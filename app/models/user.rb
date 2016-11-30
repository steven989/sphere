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
  has_many :authorizations
  has_many :plans

  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  validates :email, uniqueness: true


  def is? (user_type)
    user_type == self.user_type
  end

  def authorized_by(provider,scope)
      providers = authorizations.where("provider ilike ? and scope ilike ?",provider,"%#{scope}%")
      providers.length == 1 ? true : false
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
        Notification.create_expiry_notification(self.id,connection.id,date_of_last_activity+target_contact_interval_in_days.days,remaining_days_until_expiry)
      end

      # 2) update status of expired notifications
      if number_of_days_since_last_activity > target_contact_interval_in_days
        connection.update_attributes(active:false)
      end

      # 3) Update time score


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
