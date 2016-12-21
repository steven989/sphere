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

  # Validations
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :email, presence: true
  validates :email, email: true
  validates :email, uniqueness: true

  after_create :import_default_settings

  mount_uploader :photo, PhotoUploader


  def display_name
    (first_name || last_name) ? first_name.to_s+last_name.to_s  : email.match(/(\S+)@/)[1]
  end

  def get_raw_bubbles_data(connections_override=nil,json_or_not_json=false)
    connections = connections_override ? connections_override : self.connections.active
    result = connections.joins{ connection_score.outer }.pluck(:id,:score_quality,:score_time,:first_name,:last_name,:email,:photo_access_url).inject({}) {|accumulator,result| accumulator[result[0]] = {id:result[0],display:result[3].to_s+' '+result[4].to_s,size:result[1],distance:result[2],photo_url:result[6],email:result[5] }; accumulator }
    tags_array = tags.where(taggable_type:"Connection").group_by(&:taggable_id)
    tags_array.each do |key,value|
      if current_hash = result[key]
        current_hash[:tags] = value.map {|tagObj| tagObj.tag }
        result[key] = current_hash
      end
    end
    if json_or_not_json
      result.values.to_json
    else
      result.values
    end
  end

  def get_notifications(json_or_not_json=false)
      result = self.notifications.inject({}) do |accumulator,notification|
                  accumulator[:connection_level] = {} unless accumulator[:connection_level]
                  accumulator[:user_level] = [] unless accumulator[:user_level]
                  if notification.notification_date && notification.expiry_date && Date.today >= notification.notification_date && Date.today < notification.expiry_date
                    if notification.notifiable_type == "Connection"
                      if accumulator[:connection_level][notification.notifiable_id]
                        accumulator[:connection_level][notification.notifiable_id] = {notification_type:notification.notification_type,value:notification.value_in_specified_type,priority:notification.priority} if (notification.priority < accumulator[:connection_level][notification.notifiable_id][:priority])
                      else
                        accumulator[:connection_level][notification.notifiable_id] = {notification_type:notification.notification_type,value:notification.value_in_specified_type,priority:notification.priority}
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


  def self.create_user(email,first_name,last_name,user_type="user",password=nil,password_confirmation=nil,oauth=false)
    if oauth || !password.blank?
      user = User.new(email:email,first_name:first_name,last_name:last_name,user_type:user_type,password:password,password_confirmation:password_confirmation)
      if user.save
        StatisticDefinition.new_user_base_statistics(user)
        {status:true,user:user,message:nil}
      else
        {status:false,user:nil,message:user.errors.full_messages.join(', ')}
      end
    else
      {status:false,user:nil,message:"Password is required"}
    end
  end


  def daily_connection_tasks # put all daily connection-level tasks here so that there is one loop that runs instead of multiple loops
    
    expiring_connection_notification_period_in_days = SystemSetting.search("expiring_connection_notification_period_in_days").value_in_specified_type
    
    self.connections.each do |connection|
      # 1) create upcoming expiry notifications
      target_contact_interval_in_days = connection.target_contact_interval_in_days
      date_of_last_activity = connection.activities.where("date is not null").order(date: :desc).first.date
      number_of_days_since_last_activity = (Date.today - date_of_last_activity).to_i
      remaining_days_until_expiry = [target_contact_interval_in_days - number_of_days_since_last_activity,0].max
      if remaining_days_until_expiry <= expiring_connection_notification_period_in_days
        Notification.create_expiry_notification(self,connection,date_of_last_activity+target_contact_interval_in_days.days,remaining_days_until_expiry)
      end

      # 2) create upcoming plans notifications
      if self.plans.where(connection_id:connection.id).length > 0
        plans = self.plans.where(connection_id:connection.id)
        plan = plans.order(date: :desc).limit(1).take
        Notification.create_upcoming_plan_notification(self,connection)
      end

      # 3) update status of expired connections
      if number_of_days_since_last_activity > target_contact_interval_in_days
        if connection.plans.where("date >= ?",Date.today).length == 0
          connection.update_attributes(active:false)
        end
      end
      # 4) Update time score
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
