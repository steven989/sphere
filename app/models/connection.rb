class Connection < ActiveRecord::Base
    # Associtions
    belongs_to :user
    has_many :activities
    has_one :connection_score
    has_many :connection_score_histories
    has_many :connection_notes
    has_many :plans
    has_many :tags, as: :taggable
    has_many :notifications, as: :notifiable
    # Callbacks
    after_create :callbacks_after_create
    after_update :callbacks_after_update
    # Other stuff
    scope :active, -> { where(active:true) } 
    mount_uploader :photo, PhotoUploader

    # Methods
    def name
        first_name+" "+last_name
    end

    def self.parse_first_name(name)
      name.split(" ")[0].nil? ? nil : name.split(" ")[0].humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
    encoded

    def self.parse_last_name(name)
       last_name_array = name.split(" ")
       if last_name_array.length == 0
         nil
       else
          last_name_array.slice!(0)
          last_name_array.join(" ").humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
       end
    end

    def update_score
        current_quality_score = ConnectionScore.where(connection_id:self.id).take.blank? ? 0 :  ConnectionScore.where(connection_id:self.id).take.score_quality
        new_quality_score = self.calculate_quality_score
        new_time_score = self.calculate_time_score
        self.log_score(new_quality_score, new_time_score)
        quality_score_gained = new_quality_score - current_quality_score
        time_score_gained = nil #not using this for now; just a placeholder for potential future use
        {quality_score_gained:quality_score_gained,time_score_gained:time_score_gained}
    end

    def calculate_quality_score
        score = 0
        activities = self.activities
        # 1) Calculate the base score based on activities and weights assigned to each Relationship Quality Dimension (RQD)
        SystemSetting.search('rqd_weights').value_in_specified_type.each do |key, value|
            score += activities.joins{activity_definition.outer}.sum("activity_definitions.#{key.to_s} * #{value}").to_i
        end
        # 2) Add a bonus in for being initiated by connection
        percent_of_events_initiated_by_connection = activities.where(initiator:1).length.to_f / activities.length.to_f
        initator_bonus_settings = SystemSetting.search("initiator_bonus").value_in_specified_type
        bonus_multiplier = initiator_bonus_multiplier(percent_of_events_initiated_by_connection,initator_bonus_settings[:maximum_bonus_percent],initator_bonus_settings[:optimal_percent_of_events_initiated_by_connection],initator_bonus_settings[:point_of_zero_bonus_above_50_percent_of_events])
        
        score *= bonus_multiplier        
        score
    end

    def calculate_time_score
        date_of_last_activity = self.activities.where("date is not null").order(date: :desc).first.date
        number_of_days_since_last_activity = (Date.today - date_of_last_activity).to_i
        target_contact_interval_in_days = self.target_contact_interval_in_days ||= SystemSetting.search("default_contact_interval").value_in_specified_type
        score = ((number_of_days_since_last_activity.to_f / target_contact_interval_in_days.to_f)*10000.00).round
        score
    end

    def log_score(quality_score,time_score)
      connection_score = ConnectionScore.where(user_id:self.user_id,connection_id:self.id).take
      if connection_score.blank?
        ConnectionScore.create(user_id:self.user_id,connection_id:self.id,date_of_score:Date.today,score_quality:quality_score,score_time:time_score)
      else
        connection_score.update_attributes(date_of_score:Date.today,score_quality:quality_score,score_time:time_score)
      end
    end

    def initiator_bonus_multiplier(percent_of_events_initiated_by_connection,maximum_bonus_percent,optimal_percent_of_events_initiated_by_connection,point_of_zero_bonus_above_50_percent_of_events)
          # use a root function for input percent from 0% to the optimal %, then a 6th root function to decrease down to bonus of 0 for input percentages above the optimal %. Decided by graphically looking at the plots
          parameter_increasing = (maximum_bonus_percent.to_f)/Math.sqrt(optimal_percent_of_events_initiated_by_connection.to_f)
          parameter_decreasing = (maximum_bonus_percent.to_f)/((-(optimal_percent_of_events_initiated_by_connection.to_f - point_of_zero_bonus_above_50_percent_of_events.to_f))**(1.000/6.000))

          if percent_of_events_initiated_by_connection.to_f <= optimal_percent_of_events_initiated_by_connection.to_f
            value = parameter_increasing * Math.sqrt(percent_of_events_initiated_by_connection.to_f) + 1
          else 
            value = parameter_decreasing * (-(percent_of_events_initiated_by_connection.to_f - point_of_zero_bonus_above_50_percent_of_events.to_f))**(1.000/6.000) + 1
          end
          value.instance_of?(Complex) ? 1 : value
    end
    
    def self.import_from_google(user,access_token=nil,expires_at=nil,output_type="summarized_array")
        if access_token.nil? || access_token.nil? || Time.now > (DateTime.parse(expires_at) - 1.minute)
          token_object = user.authorizations.where(provider:'google').take.refresh_token!  
        else
          token_object = {access_token:access_token,expires_at:expires_at}
        end

        begin
          client = OAuth2::Client.new(ENV['GOOGLE_OAUTH_CLIENT_ID'],ENV['GOOGLE_OAUTH_CLIENT_SECRET'])
          oauth_access_token_for_user = OAuth2::AccessToken.new(client,token_object[:access_token])
          google_contacts_user = GoogleContactsApi::User.new(oauth_access_token_for_user)
          imported = google_contacts_user.contacts
          contacts = output_type == "api_contact_class" ? imported : imported.map {|contact| {id:contact.id,name:contact.title, email:contact.primary_email, other_emails: contact.emails.delete_if{|e| e == contact.primary_email}, phone: contact.phone_numbers }} 
        rescue => error
            status = false
            message = error.message                  
        else
          status = true
          message = "Here's your contacts from Google! Pick the ones you want to import. We'll import their photos too if available"
          {status:status,message:message,data:contacts,access_token:token_object}
        end
    end

    def self.insert_contact(user,name,email=nil,other_emails=nil,phones=nil,photo_object=nil,photo_file_upload=nil,tags=nil,notes=nil)
          # If email matches an existing contact, merge the contacts and emails addresses (keep the current name and email in app, add any new emails to "additional emails") Otherwise create a new entry in the contacts
          interval = user.user_setting.get_value(:default_contact_interval_in_days)
          if email || other_emails
            unified_email_array = []
            unified_email_array.push(email) if email
            unified_email_array += other_emails.split("|>-<+|%") if other_emails
            unified_email_array = unified_email_array.map {|email| email.gsub(" ","")} #remove any spaces in the email
            unified_email_array = unified_email_array.uniq
            unified_email_array.reject! {|email| email.strip == ""}
          else 
            unified_email_array = nil
          end

          if phones
            unified_phones_array = phones.split("|>-<+|%")
            unified_phones_array.reject! {|phone| phone.strip == ""}
            unified_phones_array = nil if unified_phones_array.blank?
          else
            unified_phones_array = nil
          end

          if !unified_email_array.blank?
            sql_where_statement = unified_email_array.map {|email| "(email ilike '%#{email}%') OR (additional_emails ilike '%#{email}%')" }.join(" OR ")
            matched_connections = user.connections.where(sql_where_statement)

            if matched_connections.length > 0
              matched_connection = matched_connections.take
              # Merge emails
              matched_connection_email = matched_connection.email
              matched_connection_other_emails = eval((matched_connection.additional_emails.blank? ? "[]" : matched_connection.additional_emails)) #will return either [] or ["some_values"]
              if matched_connection_email.blank?
                primary_email_to_update_string = unified_email_array.slice!(0)
                updated_additional_emails_array = unified_email_array
                updated_additional_emails_string = updated_additional_emails_array.to_s
              else
                primary_email_to_update = nil
                matched_connection_email.gsub!(" ","")
                additional_emails_to_merge = unified_email_array.delete_if {|email| email == matched_connection_email}
                updated_additional_emails_array = (matched_connection_other_emails + additional_emails_to_merge).uniq
                updated_additional_emails_string = updated_additional_emails_array.to_s
              end

              # Merge phone numbers
              matched_connection_phone = matched_connection.phone
              matched_connection_other_phones = eval((matched_connection.additional_phones.blank? ? "[]" : matched_connection.additional_phones)) #will return either [] or ["some_values"]
              if matched_connection_phone.blank?
                if unified_phones_array.blank?
                  primary_phone_to_update = nil
                  updated_additional_phones_string = nil
                else
                  primary_phone_to_update = unified_phones_array.slice!(0)
                  updated_additional_phones_array = (matched_connection_other_phones + unified_phones_array).uniq
                  updated_additional_phones_string = updated_additional_phones_array.to_s
                end
              else
                additional_phones_to_merge = unified_phones_array.delete_if {|phone| phone == matched_connection_phone}
                updated_additional_phones_array = (matched_connection_other_phones + additional_phones_to_merge).uniq
                primary_phone_to_update = nil
                updated_additional_phones_string = updated_additional_phones_array.to_s
              end

              (matched_connection.email = primary_email_to_update_string) if primary_email_to_update_string
              (matched_connection.additional_emails = updated_additional_emails_string) if updated_additional_emails_string
              (matched_connection.phone = primary_phone_to_update) if primary_phone_to_update
              (matched_connection.additional_phones = updated_additional_phones_string) if updated_additional_phones_string
              
              if matched_connection.save
                if photo_object && !photo_object[:body].blank?
                  encoded = Base64.strict_encode64(photo_object[:body])
                  photo_data_uri = "data:#{photo_object[:content_type]};base64,#{encoded}"
                  Connection.find(matched_connection.id).upload_photo(photo_data_uri,true) if (photo_object && !photo_object[:body].blank?)
                end
                if tags
                  connection_tags = matched_connection.tags.map {|tag| tag}
                  tags.reject! {|tag| matched_connection.include?(tag.strip)}
                  tags.each{|tag| Tag.create(tag:tag.strip,user_id:user.id,taggable_type:"Connection",taggable_id:matched_connection.id)}
                end
                Connection.port_photo_url_to_access_url(matched_connection.id)
                status = true
                message = "Connection successfully updated"
                data = matched_connection
              else
                status = false
                message = "Connection could not be saved be saved. #{matched_connection.errors.full_messages.join(', ')}"
                data = name
              end
            else

              if unified_phones_array.blank?
                primary_phone_to_update = nil
                updated_additional_phones_string = nil
              else
                primary_phone_to_update = unified_phones_array.slice!(0)
                updated_additional_phones_array = unified_phones_array.uniq
                updated_additional_phones_string = updated_additional_phones_array.to_s
              end

              first_name_to_create = Connection.parse_first_name(name)
              last_name_to_create = Connection.parse_last_name(name)
              email_to_create = email.blank? ? nil : email
              other_emails_to_create = other_emails.blank? ? "[]" : other_emails
              phone_to_create = primary_phone_to_update
              other_phones_to_create = updated_additional_phones_string

              new_connection = Connection.new(user_id:user.id,first_name:first_name_to_create,last_name:last_name_to_create,email:email_to_create,phone:phone_to_create,additional_emails:other_emails_to_create,additional_phones:other_phones_to_create,active:true,target_contact_interval_in_days:interval,notes:notes)
              
              if new_connection.save
                if photo_object && !photo_object[:body].blank?
                  encoded = Base64.strict_encode64(photo_object[:body])
                  photo_data_uri = "data:#{photo_object[:content_type]};base64,#{encoded}"
                  Connection.find(new_connection.id).upload_photo(photo_data_uri,true) if (photo_object && !photo_object[:body].blank?)
                elsif photo_file_upload
                  Connection.find(new_connection.id).upload_photo(photo_file_upload)
                end
                Connection.port_photo_url_to_access_url(new_connection.id)
                tags.each {|tag| Tag.create(tag:tag.strip,user_id:user.id,taggable_type:"Connection",taggable_id:new_connection.id) } if tags
                status = true
                message = "Connection successfully created"
                data = new_connection
              else
                status = false
                message = "Connection could not be saved be created. #{new_connection.errors.full_messages.join(', ')}"
                data = name
              end
            end
          else
              if unified_phones_array.blank?
                primary_phone_to_update = nil
                updated_additional_phones_string = nil
              else
                primary_phone_to_update = unified_phones_array.slice!(0)
                updated_additional_phones_array = unified_phones_array.uniq
                updated_additional_phones_string = updated_additional_phones_array.to_s
              end

              first_name_to_create = Connection.parse_first_name(name)
              last_name_to_create = Connection.parse_last_name(name)
              email_to_create = email.blank? ? nil : email
              other_emails_to_create = other_emails.blank? ? "[]" : other_emails
              phone_to_create = primary_phone_to_update
              other_phones_to_create = updated_additional_phones_string

              new_connection = Connection.new(user_id:user.id,first_name:first_name_to_create,last_name:last_name_to_create,email:email_to_create,phone:phone_to_create,additional_emails:other_emails_to_create,additional_phones:other_phones_to_create,active:true,target_contact_interval_in_days:interval,notes:notes)
              
              if new_connection.save
                if photo_object && !photo_object[:body].blank?
                  encoded = Base64.strict_encode64(photo_object[:body])
                  photo_data_uri = "data:#{photo_object[:content_type]};base64,#{encoded}"
                  Connection.find(new_connection.id).upload_photo(photo_data_uri,true) if (photo_object && !photo_object[:body].blank?)
                elsif photo_file_upload
                  Connection.find(new_connection.id).upload_photo(photo_file_upload)
                end
                Connection.port_photo_url_to_access_url(new_connection.id)
                tags.each {|tag| Tag.create(tag:tag.strip,user_id:user.id,taggable_type:"Connection",taggable_id:new_connection.id) } if tags
                status = true
                message = "Connection successfully created"
                data = new_connection
              else
                status = false
                message = "#{name} could not be saved be saved. #{new_connection.errors.full_messages.join(', ')}"
                data = name
              end
          end
          {status:status,message:message,data:data}
    end

    def upload_photo(photo,data_uri=false)
      self.remove_photo!
      save
      if data_uri
        self.photo_data_uri = photo
      else
        self.photo = photo
      end
      save
    end

    def self.create_from_import(user,contacts_imported,access_token=nil,expires_at=nil)
      imported_contacts = Connection.import_from_google(user,access_token,expires_at,"api_contact_class")      
      selected_imports_id_for_matching_purposes = contacts_imported.map {|selectec_contact| selectec_contact["id"] }
      selected_contacts_in_api_contact_class = imported_contacts[:data].select {|contact| selected_imports_id_for_matching_purposes.include?(contact.id)}

      result_array = []
        contacts_imported.each do |contact|
          id = contact["id"]
          name = contact["name"]
          email = contact["email"]
          phone = contact["phone"]
          other_emails = contact["other_emails"]
          photo_object = selected_contacts_in_api_contact_class.select {|contact| contact.id == id}[0].photo_with_header
          result = Connection.insert_contact(user,name,email,other_emails,phone,photo_object)
          result_array.push(result)
        end
      issues = result_array.select {|result| result[:status] == false}
      if issues.length > 0 
        status = false
        message = issues.map {|issue| issue[:message] }.join(", ")
        data = issues.map {|issue| issue[:data] }
      else
        status = true
        message = "Connections successfully created"
        data = nil
      end
      {status:status,message:message,data:data}
    end

    def find_photo
      
    end

    def update_tags(user,new_tags_array)
      begin
        tags.destroy_all
        if !new_tags_array.blank?
          new_tags_array.uniq.each {|tag| tags.create(user_id:user.id,tag:tag)}
        end
      rescue => error
        status = false
        message = error.message
        data = []
      else
        status = true
        message = "Tags successfully updated"
        data = new_tags_array.blank? ? [] : new_tags_array.uniq
      end
      {status:status,message:message,data:data}
    end

    def self.port_photo_url_to_access_url(id)
      connection = Connection.find(id)
      if connection.photo && connection.photo.file
        connection.update_attributes(photo_access_url:connection.photo.url)
      end
    end

    private

    def callbacks_after_create
      @new_record = true
    end

    def callbacks_after_update
      @photo_updated = photo_changed?
    end

end
