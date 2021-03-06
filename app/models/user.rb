class User < ActiveRecord::Base
  authenticates_with_sorcery!

  scope :app_users, -> { where(user_type:"user") } 

  # Associations
  has_many :connections
  has_many :activities
  has_many :connection_scores
  has_many :connection_score_histories
  has_many :notifications
  has_many :connection_notes
  has_many :user_statistics
  has_many :user_badges
  has_many :badges, through: :user_badges
  has_many :user_challenges
  has_many :current_challenges, -> {select("challenges.*,user_challenges.status,user_challenges.date_shown_to_user,user_challenges.date_started,user_challenges.date_to_be_completed")}, through: :user_challenges, class_name: "Challenge", foreign_key: "challenge_id", source: :challenge
  has_many :user_challenge_completeds
  has_many :completed_challenges, through: :user_challenge_completeds, class_name: "Challenge", foreign_key: "challenge_id", source: :challenge
  has_many :level_histories
  has_many :authorizations, dependent: :destroy
  has_many :plans
  has_one :user_setting, dependent: :destroy
  has_many :tags
  has_many :penalties
  has_many :external_notifications
  has_many :user_reminders, dependent: :destroy
  has_many :sign_up_codes
  has_many :app_usages

  # Validations
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :email, presence: true
  validates :email, email: true
  validates :email, uniqueness: true

  after_create :import_default_settings

  mount_uploader :photo, PhotoUploader


  def display_name
    (first_name || last_name) ? first_name.to_s+" "+last_name.to_s  : email.match(/(\S+)@/)[1]
  end

  def get_raw_bubbles_data(connections_override=nil,json_or_not_json=false,active=true)
    connections = connections_override ? connections_override : (active ? self.connections.active : self.connections.expired)
    if active
      result = ActiveRecord::Base.connection.exec_query("SELECT a.id, b.score_quality,b.score_time,a.first_name,a.last_name,a.email,a.photo_access_url,dense_rank() over (partition by a.user_id order by a.id)-1 as id_rank FROM connections a LEFT JOIN connection_scores b ON a.id = b.connection_id WHERE a.user_id = #{self.id} AND active='true'").inject({}) {|accumulator,result| accumulator[result["id"].to_i] = {id:result["id"],display:(result["first_name"].length > 9 ? result["first_name"].to_s.insert(9,"<br>") : result["first_name"].to_s)+' '+result["last_name"].to_s,size:result["score_quality"],distance:1,photo_url:result["photo_access_url"],email:result["email"],id_rank:result["id_rank"] }; accumulator }
      # result = connections.joins{ connection_score.outer }.pluck(:id,:score_quality,:score_time,:first_name,:last_name,:email,:photo_access_url).inject({}) {|accumulator,result| accumulator[result[0]] = {id:result[0],display:result[3].to_s+' '+result[4].to_s,size:result[1],distance:result[2],photo_url:result[6],email:result[5] }; accumulator }
      tags_array = tags.where(taggable_type:"Connection").group_by(&:taggable_id)
      tags_array.each do |key,value|
        if current_hash = result[key]
          current_hash[:tags] = value.map {|tagObj| tagObj.tag }
          result[key] = current_hash
        end
      end
    else
      revival_xp_requirements = connections.inject({}) {|accumulator,connection| accumulator[connection.id] = connection.calculate_revival_requirements.to_i; accumulator}
      result = connections.joins{ connection_score.outer }.pluck(:id,:score_quality,:score_time,:first_name,:last_name,:email,:photo_access_url,:date_inactive).inject({}) {|accumulator,result| accumulator[result[0]] = {id:result[0],display:result[3].to_s+' '+result[4].to_s,size:result[1],distance:result[2],photo_url:result[6],email:result[5],date_inactive:(result[7] ? result[7].strftime("%b %-d, %Y") : ""),xp_requirements:revival_xp_requirements[result[0]]}; accumulator }
    end

    if json_or_not_json
      result.values.to_json
    else
      result.values
    end
  end

  def completed_initial_add_three_connections_challenge
      UserChallengeCompleted.create(
          user_id:self.id,
          date_shown_to_user:Date.today,
          date_completed:Date.today,
          method_of_completion:"completed",
          repeated_allowed:false,
          date_started:Date.today,
          reward:800,
          date_to_be_completed:Date.today
          )
      StatisticDefinition.trigger("xp",self)
      StatisticDefinition.trigger("level",self)
      Notification.create_one_time_add_3_contacts_notification(self)
  end

  def level_up
    current_level = self.stat("level")
    new_level = Level.find_level_for(self)
    if new_level > current_level
      stat = user_statistics.find_statistic("level").take
      stat.update_attributes(value:new_level)
      Notification.create_new_level_notification(self,current_level,new_level,1)
    end
  end

  def get_notifications(json_or_not_json=false)
      expiring_connection_array_of_ids = []
      result = self.notifications.order(priority: :desc).inject({}) do |accumulator,notification|
                  accumulator[:connection_level] = {} unless accumulator[:connection_level]
                  accumulator[:user_level] = [] unless accumulator[:user_level]
                  if (notification.notification_date && Date.today >= notification.notification_date) && ( !notification.expiry_date || (notification.expiry_date && Date.today <= notification.expiry_date))
                    if notification.notifiable_type == "Connection"
                      if accumulator[:connection_level][notification.notifiable_id]
                        accumulator[:connection_level][notification.notifiable_id] = {notification_type:notification.notification_type,value:notification.value_in_specified_type,priority:notification.priority} if (notification.priority < accumulator[:connection_level][notification.notifiable_id][:priority])
                      else
                        accumulator[:connection_level][notification.notifiable_id] = {notification_type:notification.notification_type,value:notification.value_in_specified_type,priority:notification.priority}
                      end
                      if notification.notification_type == "connection_expiration" #user-level notification accumulated from connection-level expiry counts
                        expiring_connection_array_of_ids.push(notification.notifiable_id)
                      elsif notification.notification_type == "upcoming_plan"
                        expiring_connection_array_of_ids.reject! {|connection_id| connection_id == notification.notifiable_id}
                      end
                    else
                      existing_notification = accumulator[:user_level].select {|notification_in_array| notification_in_array[:notification_type] == notification.notification_type}[0]
                      if existing_notification
                        existing_notification[:count] = existing_notification[:count]+1
                        existing_notification[:values].push(notification.value_in_specified_type)
                      else
                        accumulator[:user_level].push({notification_type:notification.notification_type,values:[notification.value_in_specified_type],count:1})
                      end
                    end
                  end
                  accumulator
                end
        result[:user_level].push({notification_type:"my_sphere", count: expiring_connection_array_of_ids.length}) if expiring_connection_array_of_ids.length > 0
      if json_or_not_json
        result.to_json
      else
        result
      end
  end

  def get_timezone
    self.timezone ? TZInfo::Timezone.get(self.timezone) : TZInfo::Timezone.get('America/New_York')
  end

  def send_events_and_reminder_email
    if self.user_setting.get_value('send_events_reminders_emails')
      timezone = self.get_timezone
      date_today_in_timezone = timezone.now.strftime("%Y-%m-%d").to_date
      date_tomorrow_in_timezone = date_today_in_timezone + 1.day
      boundary_beginning_time_in_utc = timezone.local_to_utc(Time.local(date_today_in_timezone.year,date_today_in_timezone.month,date_today_in_timezone.day,0,0,0))
      boundary_ending_time_in_utc = timezone.local_to_utc(Time.local(date_tomorrow_in_timezone.year,date_tomorrow_in_timezone.month,date_tomorrow_in_timezone.day,0,0,0))
      events_today = self.plans.where("status ilike 'Planned' and date_time >= ? and date_time < ?", boundary_beginning_time_in_utc,boundary_ending_time_in_utc)
      reminders_today = self.user_reminders.set.where("due_date = ? or (due_date is null and (created_at::date = ? or created_at::date = ?))",date_today_in_timezone,Date.today-7.days,Date.today-21.days)
      if !events_today.blank? || !reminders_today.blank?
        unless SentEmail.where(user_id:self.id,sent_date:Date.today,source:"send_events_and_reminder_email").length > 0
          SystemMailer.events_and_reminders(self,events_today,reminders_today,timezone).deliver 
          SentEmail.create(user_id:self.id,sent_date:Date.today,allowable_frequency:"daily",source:"send_events_and_reminder_email")
        end
      end
    end
  end

  def get_one_time_popup_notification(json_or_not_json=false)
    notification = notifications.where("one_time_display = true and notification_type not ilike 'new_feature'").order(priority: :asc).take
    if notification
      if notification.notification_type == 'level_up'
        element_id = 'levelUpNotificationPopup'
        value_1 = notification.value_in_specified_type[:new_level]
        result = {id:notification.id,element_id:element_id,value_1:value_1}
      elsif notification.notification_type == 'new_badges_one_time'
        element_id = 'newBadgePopup'
        value_1 = notification.value_in_specified_type
        result = {id:notification.id,element_id:element_id,value_1:value_1}
      elsif notification.notification_type == 'added_first_3_users_in_time'
        element_id = 'addedFirstThreeConnectionsPopup'
        value_1 = 'null'
        result = {id:notification.id,element_id:element_id,value_1:value_1}
      else
        result=nil
      end
    else
      result = nil
    end
    if json_or_not_json
      result.to_json
    else
      result
    end
  end

  def get_one_time_tooltip_notification(json_or_not_json=false)
    notification = notifications.where("one_time_display = 'true' and notification_type ilike 'new_feature'").take
    if notification
      if notification.notification_type == 'new_feature'
        element = '.checkinButton.longPressTransition'
        message = "Press and HOLD if you wan to add detailed notes to your check in"
        result = {notification:notification,element:element,message:message,position:'top'}
      else
        result=nil
      end
    else
      result = nil
    end
    if json_or_not_json
      result.to_json
    else
      result
    end
  end

  def get_bubbles_display_system_settings(json_or_not_json=false)
        bubbles_parameters_object = SystemSetting.search("bubbles_parameters").value_in_specified_type
        bubbles_parameters = {
          sizeOfGapBetweenBubbles:bubbles_parameters_object[:min_gap_between_bubbles],
          minDistance:bubbles_parameters_object[:min_distance_from_center_of_central_bubble],
          minBubbleSize:bubbles_parameters_object[:min_size_of_bubbles],
          maxBubbleSize:bubbles_parameters_object[:max_size_of_bubbles],
          numberOfRecursion:bubbles_parameters_object[:number_of_recursions],
          radiusOfCentralBubble:bubbles_parameters_object[:radius_of_central_bubble],
          centralBubbleDisplay:self.display_name,
          centralBubblePhotoURL:self.photo_url
          }
          if json_or_not_json
            bubbles_parameters.to_json
          else
            bubbles_parameters
          end
  end

  def find_challenges
    additional_challenges = Challenge.identify_challenges_for(self)
    if additional_challenges.length > 0 
      additional_challenges.each do |challenge|
        user_challenge = self.user_challenges.create(
                        challenge_id:challenge.id,
                        date_shown_to_user:Date.today
                        )
        Notification.create_new_challenge_notification(user_challenge)
      end
    end
  end

  def find_badges
    additional_badges = Badge.identify_badges_for(self)
    if additional_badges.length > 0
      additional_badges.each do |badge|
        user_badge = self.user_badges.create(badge_id:badge.id)
        Notification.create_new_badge_notification(user_badge)
      end
      Notification.create_one_time_badge_notification(self,additional_badges.length)
    end
  end


  def import_default_settings
    UserSetting.create_from_system_settings(self)
  end

  def level
    current_level = stat('level')
    level = Level.where(level:current_level)
    level.blank? ? nil : level.take
  end


  def stat(statistic)
    stat = user_statistics.find_statistic(statistic)
    stat.blank? ? nil : stat.take.value_in_type
  end

  def stats
    user_statistics.inject({}){|result,element| result[element.name.to_sym] = element.value_in_type; result }
  end

  def update_stats(stats={})
    stats.each do |key,value|
      stat_to_update = self.user_statistics.where(name:key)
      if stat_to_update.length == 1
        stat_to_update.take.update_attributes(value:value)
      end
    end
  end

  def is? (user_type)
    user_type == self.user_type
  end

  def self.find_email(email)
    User.where(email:email).take
  end

  def authorized_by(provider,scope)
      providers = authorizations.where("provider ilike ? and scope ilike ?",provider,"%#{scope}%")
      providers.length == 1 ? true : false
  end


  def self.create_user(email,first_name,last_name,user_type="user",password=nil,password_confirmation=nil,oauth=false,invite_code=nil)
    if SystemSetting.search('invite_code_required').value_in_specified_type 
      if !invite_code.blank?
        check_result = SignUpCode.check_if_code_is_valid(invite_code)
        if check_result[:status]
          if oauth || !password.blank?
            user = User.new(email:email,first_name:first_name,last_name:last_name,user_type:user_type,password:password,password_confirmation:password_confirmation)
            if user.save
              SystemMailer.delay.welcome_email(user)
              SystemMailer.welcome_email(user).deliver
              SignUpCode.create_sign_up_codes(user)
              StatisticDefinition.new_user_base_statistics(user)
              SignUpCode.increment(invite_code)
              user.find_challenges
              {status:true,user:user,message:nil}
            else
              {status:false,user:nil,message:user.errors.full_messages.join(', ')}
            end
          else
            {status:false,user:nil,message:"Password is required"}
          end
        else
          {status:false,user:nil,message:check_result[:message]}
        end
      else
        {status:false,user:nil,message:"Please enter your invite code!"}
      end
    else 
      if oauth || !password.blank?
        user = User.new(email:email,first_name:first_name,last_name:last_name,user_type:user_type,password:password,password_confirmation:password_confirmation)
        if user.save
          SystemMailer.delay.welcome_email(user)
          SignUpCode.create_sign_up_codes(user)
          StatisticDefinition.new_user_base_statistics(user)
          user.find_challenges
          {status:true,user:user,message:nil}
        else
          {status:false,user:nil,message:user.errors.full_messages.join(', ')}
        end
      else
        {status:false,user:nil,message:"Password is required"}
      end
    end

  end

  def daily_connection_tasks # put all daily connection-level tasks here so that there is one loop that runs instead of multiple loops
    
    expiring_connection_notification_period_in_days = SystemSetting.search("expiring_connection_notification_period_in_days").value_in_specified_type
    timezone = self.timezone ? TZInfo::Timezone.get(self.timezone) : TZInfo::Timezone.get('America/New_York')

    self.connections.active.each do |connection|
      # 1) Account for events 
      if connection.plans.where("status ilike 'Planned' and date_time >= ? and date_time < ?",Date.today-1,Date.today).length > 0
        connection.update_attributes(active:true,times_degraded:0)
      end
      # 2) update status of expired connections
      target_contact_interval_in_days = connection.target_contact_interval_in_days
      date_of_last_activity = timezone.utc_to_local(connection.activities.where("date is not null").order(date: :desc).first.created_at).strftime("%Y-%m-%d").to_date
      date_of_last_plan = Plan.last(self,connection) ? timezone.utc_to_local(Plan.last(self,connection).date_time).strftime("%Y-%m-%d").to_date : nil
      if date_of_last_plan.nil?
        combined_date_of_last_activity = date_of_last_activity
      else
        combined_date_of_last_activity = date_of_last_activity > date_of_last_plan ? date_of_last_activity : date_of_last_plan
      end
      
      number_of_days_since_last_activity = (timezone.now.strftime("%Y-%m-%d").to_date - combined_date_of_last_activity).to_i
      if number_of_days_since_last_activity > target_contact_interval_in_days
        if connection.plans.where("date_time >= ?",timezone.local_to_utc(timezone.now)).length == 0
          connection.degrade
        end
      end

      if Connection.find(connection.id).active
        # 3) create upcoming expiry notifications
        connection.check_if_connection_is_expiring_and_if_so_create_notification(self,expiring_connection_notification_period_in_days)
        
        # 4) create upcoming plans notifications
        if self.plans.where(connection_id:connection.id).length > 0
          plans = self.plans.where(connection_id:connection.id)
          plan = plans.order(date: :desc).limit(1).take
          Notification.create_upcoming_plan_notification(self,connection)
        end
      end

      # 5) Update quality and time score
      connection.update_score
    end
  end

  def calculate_quality_score_for_active_connections
      self.connections.active.each do |connection|
        connection.update_score
      end
  end


  def self.find_users_matching_criteria(criteria,return_all_stats=false)
    if return_all_stats
      stats = StatisticDefinition.all.map {|stat| stat.name}
    else
      stat_specified = criteria.scan(/@[^@]+@/).uniq
      stats = stat_specified.map {|stat| stat.gsub("@","").downcase}
    end
    sql_base_table_select_statement = stats.map {|stat| "max(case when b.name ilike '#{stat}' then b.value else null end) as #{stat}"}.join(",")
    sql_base_table_select_statement_with_leading_comma = ","+sql_base_table_select_statement

    begin
      sql = "SELECT a.* FROM (SELECT a.id as user_id#{sql_base_table_select_statement_with_leading_comma} FROM users a LEFT JOIN user_statistics b on a.id = b.user_id GROUP BY a.id) a WHERE (#{User.decode_criteria_into_sql_where_statement(criteria)})"
      result = ActiveRecord::Base.connection.exec_query(sql)
    rescue => error
      status = false
      message = error.message
      data = nil
    else
      status = true
      message = "User query successfully completed"
      data = result.to_a
    end
    {status:status,message:message,data:data}
  end

  def self.decode_criteria_into_sql_where_statement(criteria)
      criteriaDup = criteria.dup
      stat_specified = criteriaDup.scan(/@[^@]+@/).uniq
      operators_specified = criteriaDup.scan(/#[^#]+#/).uniq
      operator_dictionary = {"and" => "AND", "or" => "OR"}        
      stat_with_replacement = stat_specified.map {|stat| {stat => "a.#{stat.gsub('@','')}"} }
      operator_with_replacement = operators_specified.map {|operator| {operator => "#{operator_dictionary[operator.gsub('#','').downcase]}"} }
      stat_with_replacement.each {|replacement| criteriaDup.gsub!(replacement.keys[0],replacement.values[0]) }
      operator_with_replacement.each {|replacement| criteriaDup.gsub!(replacement.keys[0],replacement.values[0]) }
      criteriaDup.gsub!("==","=")
      criteriaDup
  end



end
