class User < ActiveRecord::Base
  authenticates_with_sorcery!
  has_many :connections
  has_many :activities  
  has_many :connection_scores
  has_many :connection_score_histories
  has_many :notifications

  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  validates :email, uniqueness: true


  def create_notifications
    # 1) Notification for soon-to-expire connections
    expiring_connection_notification_period_in_days = SystemSetting.search("expiring_connection_notification_period_in_days").value_in_specified_type
    self.connections.each do |connection|
      target_contact_interval_in_days = connection.target_contact_interval_in_days
      date_of_last_activity = connection.activities.where("date is not null").order(date: :desc).first.date
      number_of_days_since_last_activity = (Date.today - date_of_last_activity).to_i
      remaining_days_until_expiry = [target_contact_interval_in_days - number_of_days_since_last_activity,0].max

      if remaining_days_until_expiry <= expiring_connection_notification_period_in_days
        Notification.create_expiry_notification(self.id,connection.id,date_of_last_activity+target_contact_interval_in_days.days,remaining_days_until_expiry)
      end
    end
  end

  def calculate_quality_score_for_all_connections
 
      self.connections.each do |connection|
        connection.update_score
      end
      
  end

end
