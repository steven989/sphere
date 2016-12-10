class User < ActiveRecord::Base
  authenticates_with_sorcery!
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
  has_many :current_challenges, through: :user_challenges, class_name: "Challenge", foreign_key: "challenge_id", source: :challenge
  has_many :user_challenge_completeds
  has_many :completed_challenges, through: :user_challenge_completeds, class_name: "Challenge", foreign_key: "challenge_id", source: :challenge
  has_many :level_histories
  has_many :authorizations, dependent: :destroy
  has_many :plans
  has_one :user_setting, dependent: :destroy
  has_many :tags

  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :email, uniqueness: true

  after_create :import_default_settings


  def find_challenges
    additional_challenges = Challenge.identify_challenges_for(self)
    if additional_challenges.length > 0 
      additional_challenges.each do |challenge|
        self.user_challenges.create(challenge_id:challenge.id)
        Notification.create_new_challenge_notification(challenge)
      end
    end
  end

  def find_badges
    additional_badges = Badge.identify_badges_for(self)
    if additional_badges.length > 0 
      additional_badges.each do |badge|
        self.user_badges.create(badge_id:badge.id)
        Notification.create_new_badge_notification(badge)
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
      if plans = self.plans.where(connection_id:connection.id).length > 0
        plan = plans.order(date: :desc).limit(1).take
        Notification.create_upcoming_plan_notification(self,connection,plan)
      end

      # 3) update status of expired notifications
      if number_of_days_since_last_activity > target_contact_interval_in_days
        if connection.plans.where(date>=Date.today).length == 0
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
      criteriaDup
  end



end
