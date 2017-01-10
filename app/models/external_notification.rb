class ExternalNotification < ActiveRecord::Base
    belongs_to :user

    def self.send_external_notifications_for(user)
        notification_frequency = user.user_setting.get_value('expiry_notification_email_frequency') ? user.user_setting.get_value('expiry_notification_email_frequency') : 'weekly'
        last_notification = user.external_notifications.order(created_at: :desc).take
        send_notification = false
        if notification_frequency == 'daily'
            if (last_notification.nil? || (Date.today > last_notification.created_at.to_date))
                send_notification = true
            end
        elsif notification_frequency == 'weekly'
            if (last_notification.nil? || (Date.today.year > last_notification.created_at.year) || (Date.today.strftime("%V").to_i > last_notification.created_at.to_date.strftime("%V").to_i))
                send_notification = true
            end
        elsif notification_frequency == 'monthly'
            if (last_notification.nil? || (Date.today.year > last_notification.created_at.year) || (Date.today.month > last_notification.created_at.month))
                send_notification = true
            end
        end

        if send_notification
            number_of_expiring_connections = user.notifications.where("notification_type ilike ? and expiry_date >= ?","connection_expiration",Date.today).length
            SystemMailer.expiring_connections_notification(number_of_expiring_connections,user).deliver if number_of_expiring_connections > 0
        end
    end

end
