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
    has_many :user_reminders
    # Callbacks
    after_create :callbacks_after_create
    after_update :callbacks_after_update
    # Other stuff
    scope :active, -> { where(active:true) }
    scope :expired, -> { where(active:false) }
    mount_uploader :photo, PhotoUploader
    # Validations
    validates :email, email: true, allow_blank: true

    def name
        first_name.to_s+" "+last_name.to_s
    end

    def get_user_reminders(to_json=false,timezone)
      result = self.user_reminders.set.order(due_date: :desc).map {|reminder| {id:reminder.id,reminder:reminder.reminder,due_date:reminder.due_date_humanized(timezone)} }
      if to_json
        result.to_json
      else
        result
      end
    end

    def self.parse_first_name(name)
      name.split(" ")[0].nil? ? nil : name.split(" ")[0].strip.humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
    end

    def self.extract_display_name_from_email(email)
      if email.blank?
        nil
      else
        email.match(/(\S+)@/)[1]
      end
    end

    def self.parse_last_name(name)
       last_name_array = name.split(" ")
       if last_name_array.length == 0 
         nil
       else
          last_name_array.slice!(0)
          last_name_array.join(" ").strip.humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
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
        
        # 3) Factor in any completed events (for now just count each event as a "check in" from activity definitions not matter what the event)
        single_check_in_score = 0
        SystemSetting.search('rqd_weights').value_in_specified_type.each do |key, value|
          single_check_in_score += ActivityDefinition.where(activity:"Check In").sum("#{key.to_s}*#{value}").to_i
        end
        score += plans.completed.length * single_check_in_score
        
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

    def calculate_revival_requirements
        base_score = self.connection_score.score_quality * 0.05
        minimum = self.user.stat("xp") * 0.002
        maximum = self.user.stat("xp") * 0.015
        [[base_score,maximum].min,minimum].max.to_i
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
        begin
          if access_token.nil? || access_token.nil? || Time.now > (DateTime.parse(expires_at) - 1.minute)
            token_object = user.authorizations.where(provider:'google').take.refresh_token!  
          else
            token_object = {access_token:access_token,expires_at:expires_at}
          end
          client = OAuth2::Client.new(ENV['GOOGLE_OAUTH_CLIENT_ID'],ENV['GOOGLE_OAUTH_CLIENT_SECRET'])
          oauth_access_token_for_user = OAuth2::AccessToken.new(client,token_object[:access_token])
          google_contacts_user = GoogleContactsApi::User.new(oauth_access_token_for_user)
          imported = google_contacts_user.contacts
          existing_contacts = user.connections.map{|connection| connection.email }
          contacts = output_type == "api_contact_class" ? imported : imported.inject([]) {|accumulator,contact| accumulator.push({id:contact.id,name:contact.title, email:contact.primary_email, other_emails: contact.emails.delete_if{|e| e == contact.primary_email}, phone: contact.phone_numbers }) unless existing_contacts.include?(contact.primary_email); accumulator} 
        rescue => error
            status = false
            message = error.message
        else
          status = true
          message = "Here's your contacts from Google! Pick the ones you want to import. We'll import their photos too if available"
        end
        {status:status,message:message,data:contacts,access_token:token_object}
    end

    def self.insert_contact(user,name,email=nil,other_emails=nil,phones=nil,photo_object=nil,photo_file_upload=nil,tags=nil,notes=nil,merge_name=true)
      max_connections = user.user_setting.get_value('max_number_of_connections')
      max_connections = max_connections ? max_connections.to_i : 50
      if user.stat('total_connections_added').blank? || user.stat('total_connections_added') < max_connections
            # If email matches an existing contact, merge the contacts and emails addresses (keep the current name and email in app, add any new emails to "additional emails") Otherwise create a new entry in the contacts
            interval = user.user_setting.get_value(:default_contact_interval_in_days)
            if email || other_emails
              unified_email_array = []
              unified_email_array.push(email) if email
              unified_email_array += other_emails.split("|>-<+|%") if other_emails
              unified_email_array = unified_email_array.map {|email| email.gsub(" ","")} #remove any spaces in the email
              unified_email_array = unified_email_array.uniq
              unified_email_array.reject! {|email| email.strip == "" || email == "NULL" || email == "null" || email == "nil" || email == "NIL"}
              unified_email_array = nil if unified_email_array.length == 0
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

            first_name_parsed = Connection.parse_first_name(name)
            last_name_parsed = Connection.parse_last_name(name)

            if !first_name_parsed.blank? && !last_name_parsed.blank? && user.connections.where(first_name:first_name_parsed,last_name:last_name_parsed).length > 0 && merge_name
              matched_connection = user.connections.where(first_name:first_name_parsed,last_name:last_name_parsed).take

              # Merge emails
              matched_connection_email = matched_connection.email
              matched_connection_other_emails = eval((matched_connection.additional_emails.blank? ? "[]" : matched_connection.additional_emails)) #will return either [] or ["some_values"]
              if matched_connection_email.blank?
                primary_email_to_update_string = unified_email_array.nil? || unified_email_array.length == 0 ? nil : unified_email_array.slice!(0)
                updated_additional_emails_array = unified_email_array.nil? || unified_email_array.length == 0 ? nil : unified_email_array
                updated_additional_emails_string = updated_additional_emails_array.blank? ? nil : updated_additional_emails_array.to_s
              else
                primary_email_to_update = nil
                matched_connection_email.gsub!(" ","")
                additional_emails_to_merge = unified_email_array ? unified_email_array.delete_if {|email| email == matched_connection_email} : []
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
                if unified_phones_array.blank?
                  primary_phone_to_update = nil
                  updated_additional_phones_string = nil                
                else
                  additional_phones_to_merge = unified_phones_array.delete_if {|phone| phone == matched_connection_phone}
                  updated_additional_phones_array = (matched_connection_other_phones + additional_phones_to_merge).uniq
                  primary_phone_to_update = nil
                  updated_additional_phones_string = updated_additional_phones_array.to_s
                end
              end

              (matched_connection.email = primary_email_to_update_string) if primary_email_to_update_string
              (matched_connection.additional_emails = updated_additional_emails_string) if updated_additional_emails_string
              (matched_connection.phone = primary_phone_to_update) if primary_phone_to_update
              (matched_connection.additional_phones = updated_additional_phones_string) if updated_additional_phones_string
              
              if matched_connection.save
                if photo_object && !photo_object[:body].blank?
                  encoded = Base64.strict_encode64(photo_object[:body])
                  photo_data_uri = "data:#{photo_object[:content_type]};base64,#{encoded}"
                  Connection.find(matched_connection.id).upload_photo(photo_data_uri,true)
                elsif photo_file_upload
                  Connection.find(matched_connection.id).upload_photo(photo_file_upload)
                end
                if tags
                  connection_tags = matched_connection.tags.map {|tag| tag}
                  tags.reject! {|tag| connection_tags.include?(tag.strip)}
                  tags.each{|tag| Tag.create(tag:tag.strip,user_id:user.id,taggable_type:"Connection",taggable_id:matched_connection.id)}
                end
                Connection.port_photo_url_to_access_url(matched_connection.id)
                StatisticDefinition.triggers("individual","create_connection",User.find(user.id))
                status = true
                message = "Connection successfully updated"
                data = matched_connection
              else
                status = false
                message = "Connection could not be saved be saved. #{matched_connection.errors.full_messages.join(', ')}"
                data = name
              end
            else
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
                    if unified_phones_array.blank?
                      primary_phone_to_update = nil
                      updated_additional_phones_string = nil                
                    else
                      additional_phones_to_merge = unified_phones_array.delete_if {|phone| phone == matched_connection_phone}
                      updated_additional_phones_array = (matched_connection_other_phones + additional_phones_to_merge).uniq
                      primary_phone_to_update = nil
                      updated_additional_phones_string = updated_additional_phones_array.to_s
                    end
                  end

                  (matched_connection.email = primary_email_to_update_string) if primary_email_to_update_string
                  (matched_connection.additional_emails = updated_additional_emails_string) if updated_additional_emails_string
                  (matched_connection.phone = primary_phone_to_update) if primary_phone_to_update
                  (matched_connection.additional_phones = updated_additional_phones_string) if updated_additional_phones_string
                  
                  if matched_connection.save
                    if photo_object && !photo_object[:body].blank?
                      encoded = Base64.strict_encode64(photo_object[:body])
                      photo_data_uri = "data:#{photo_object[:content_type]};base64,#{encoded}"
                      Connection.find(matched_connection.id).upload_photo(photo_data_uri,true)
                    elsif photo_file_upload
                      Connection.find(matched_connection.id).upload_photo(photo_file_upload)
                    end
                    if tags
                      connection_tags = matched_connection.tags.map {|tag| tag}
                      tags.reject! {|tag| connection_tags.include?(tag.strip)}
                      tags.each{|tag| Tag.create(tag:tag.strip,user_id:user.id,taggable_type:"Connection",taggable_id:matched_connection.id)}
                    end
                    Connection.port_photo_url_to_access_url(matched_connection.id)
                    StatisticDefinition.triggers("individual","create_connection",User.find(user.id))
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

                  first_name_to_create = first_name_parsed
                  first_name_to_create = first_name_to_create.nil? ? Connection.extract_display_name_from_email(email) : first_name_to_create
                  last_name_to_create = last_name_parsed
                  email_to_create = email.blank? ? nil : email
                  other_emails_to_create = other_emails.blank? ? "[]" : other_emails
                  phone_to_create = primary_phone_to_update
                  other_phones_to_create = updated_additional_phones_string

                  new_connection = Connection.new(user_id:user.id,first_name:first_name_to_create,last_name:last_name_to_create,email:email_to_create,phone:phone_to_create,additional_emails:other_emails_to_create,additional_phones:other_phones_to_create,active:true,target_contact_interval_in_days:interval,notes:notes)

                  if new_connection.save
                    if photo_object && !photo_object[:body].blank?
                      encoded = Base64.strict_encode64(photo_object[:body])
                      photo_data_uri = "data:#{photo_object[:content_type]};base64,#{encoded}"
                      Connection.find(new_connection.id).upload_photo(photo_data_uri,true)
                    elsif photo_file_upload
                      Connection.find(new_connection.id).upload_photo(photo_file_upload)
                    end
                    user.activities.create(connection_id:new_connection.id,activity:"Added to Sphere",date:Date.today,initiator:0,activity_description:"Automatically created")
                    new_connection.update_score
                    Connection.port_photo_url_to_access_url(new_connection.id)
                    tags.each {|tag| Tag.create(tag:tag.strip,user_id:user.id,taggable_type:"Connection",taggable_id:new_connection.id) } if tags
                    StatisticDefinition.triggers("individual","create_connection",User.find(user.id))
                    status = true
                    message = "Connection successfully created"
                    data = new_connection
                  else
                    status = false
                    message = "Connection could not be saved be created. #{new_connection.errors.full_messages.join(', ')}"
                    data = new_connection
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

                  first_name_to_create = first_name_parsed
                  first_name_to_create = first_name_to_create.nil? ? Connection.extract_display_name_from_email(email) : first_name_to_create
                  last_name_to_create = last_name_parsed
                  email_to_create = email.blank? ? nil : email
                  other_emails_to_create = other_emails.blank? ? "[]" : other_emails
                  phone_to_create = primary_phone_to_update
                  other_phones_to_create = updated_additional_phones_string

                  new_connection = Connection.new(user_id:user.id,first_name:first_name_to_create,last_name:last_name_to_create,email:email_to_create,phone:phone_to_create,additional_emails:other_emails_to_create,additional_phones:other_phones_to_create,active:true,target_contact_interval_in_days:interval,notes:notes)

                  if new_connection.save
                    if photo_object && !photo_object[:body].blank?
                      encoded = Base64.strict_encode64(photo_object[:body])
                      photo_data_uri = "data:#{photo_object[:content_type]};base64,#{encoded}"
                      Connection.find(new_connection.id).upload_photo(photo_data_uri,true)
                    elsif photo_file_upload
                      Connection.find(new_connection.id).upload_photo(photo_file_upload)
                    end
                    user.activities.create(connection_id:new_connection.id,activity:"Added to Sphere",date:Date.today,initiator:0,activity_description:"Automatically created")
                    new_connection.update_score
                    Connection.port_photo_url_to_access_url(new_connection.id)
                    tags.each {|tag| Tag.create(tag:tag.strip,user_id:user.id,taggable_type:"Connection",taggable_id:new_connection.id) } if tags
                    StatisticDefinition.triggers("individual","create_connection",User.find(user.id))
                    status = true
                    message = "Connection successfully created"
                    data = new_connection
                  else
                    status = false
                    message = "#{name} could not be saved be saved. #{new_connection.errors.full_messages.join(', ')}"
                    data = new_connection
                  end
              end
            end
      else
        status = false
        message = "#{name} could not be saved be saved. Connections limited to #{max_connections}"
        data = nil
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

    def self.create_from_import(user,contacts_imported,access_token=nil,expires_at=nil,merge_name=true)
      begin
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
            result = Connection.insert_contact(user,name,email,other_emails,phone,photo_object,nil,nil,nil,merge_name)
            result_array.push(result)
          end
        rescue => error
          status = false
          message = "Uh oh. We ran into some errors: #{error.message}. Please try again. If it still won't work, please let us know!"
          data = nil
        else
          issues = result_array.select {|result| result[:status] == false}
          if issues.length > 0 
            status = false
            message = issues.map {|issue| issue[:message] }.join(", ")
            data = issues.map {|issue| issue[:data] }
          else
            AppUsage.log_action("Imported contacts",user)
            status = true
            message = "Connections successfully created"
            data = nil
          end
        end
      StatisticDefinition.triggers("individual","post_create_connection",User.find(user.id))
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

    def expire
        self.update_attributes(active:false,date_inactive:Date.today)
        self.notifications.destroy_all
    end

    def check_if_conection_is_expiring_and_if_so_create_notification(user,expiring_connection_notification_period_in_days)
        target_contact_interval_in_days = self.target_contact_interval_in_days
        date_of_last_activity = self.activities.where("date is not null").order(date: :desc).first.date
        number_of_days_since_last_activity = (Date.today - date_of_last_activity).to_i
        remaining_days_until_expiry = [target_contact_interval_in_days - number_of_days_since_last_activity,0].max
        if remaining_days_until_expiry <= expiring_connection_notification_period_in_days
          Notification.create_expiry_notification(user,self,date_of_last_activity+target_contact_interval_in_days.days,remaining_days_until_expiry)
        end
    end

    def revive
      penalty_amount = self.calculate_revival_requirements.to_i
      if self.user.stat("xp") >= penalty_amount
        self.user.penalties.create(
          statistic_definition_id:StatisticDefinition.search("xp").id,
          penalty_date:Date.today,
          penalty_statistic:'xp',
          penalty_type:"Reviving expired connection",
          amount:penalty_amount
          )
        self.update_attributes(active:true,date_inactive:nil)
        expiring_connection_notification_period_in_days = SystemSetting.search("expiring_connection_notification_period_in_days").value_in_specified_type
        self.check_if_conection_is_expiring_and_if_so_create_notification(self.user,expiring_connection_notification_period_in_days)
        Activity.create(user:self.user,connection_id:self.id,activity:"Returned from expired connections",date:Date.today,initiator:0,activity_description:"No points")
        StatisticDefinition.triggers("individual","connection_revive",self.user)
        AppUsage.log_action("Re-added expired connection",self.user)
        status = true
        message = "Successfully added#{" "+self.first_name} back to your Sphere! -#{penalty_amount} points"
      else
        status = false
        message = "Your current XP is #{self.user.stat("xp")}, not enough for the #{penalty_amount} required to re-add#{" "+self.first_name}! Check in with your connections or complete challenges to earn more XP"
      end
      {status:status,message:message}
    end

    def belongs_to?(user)
      self.user == user
    end

    private

    def callbacks_after_create
      @new_record = true
    end

    def callbacks_after_update
      @photo_updated = photo_changed?
    end

end
