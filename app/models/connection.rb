class Connection < ActiveRecord::Base
    belongs_to :user
    has_many :activities
    has_one :connection_score
    has_many :connection_score_histories
    has_many :connection_notes
    has_many :plans
    scope :active, -> { where(active:true) } 
    mount_uploader :photo, PhotoUploader

    def name
        first_name+" "+last_name
    end

    def self.parse_first_name(name)
      name.split(" ")[0].humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
    end

    def self.parse_last_name(name)
       last_name_array = name.split(" ")
       last_name_array.slice!(0)
       last_name_array.join(" ").humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
    end

    def update_score
        self.log_score(self.calculate_quality_score, self.calculate_time_score)
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
    
    def self.import_from_google(user,access_token=nil,expires_at=nil)
        if access_token.nil? || access_token.nil? || Time.now > (DateTime.parse(expires_at) - 1.minute)
          token_object = user.authorizations.where(provider:'google').take.refresh_token!  
        else
          token_object = {access_token:access_token,expires_at:expires_at}
        end


        begin
          client = OAuth2::Client.new(ENV['GOOGLE_OAUTH_CLIENT_ID'],ENV['GOOGLE_OAUTH_CLIENT_SECRET'])
          oauth_access_token_for_user = OAuth2::AccessToken.new(client,token_object[:access_token])
          google_contacts_user = GoogleContactsApi::User.new(oauth_access_token_for_user)
          contacts = google_contacts_user.contacts.map {|contact| {name:contact.title, email:contact.primary_email, other_emails: contact.emails.delete_if{|e| e == contact.primary_email}, phone: contact.phone_numbers }} 
        rescue => error
            status = false
            message = error.message                  
        else
          status = true
          message = "Contacts successfully imported from Google"
          {status:status,message:message,data:contacts,access_token:token_object}
        end
    end

end
