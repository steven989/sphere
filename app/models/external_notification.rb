class ExternalNotification < ActiveRecord::Base
    belongs_to :user

    def self.send_external_notifications_for(user)
        notification_frequency = user.user_setting.get_value('expiry_notification_email_frequency') ? user.user_setting.get_value('expiry_notification_email_frequency') : 'weekly'
        last_notification = user.external_notifications.order(created_at: :desc).take
        send_notification = false
        if notification_frequency.downcase == 'daily'
            if (last_notification.nil? || (Date.today > last_notification.created_at.to_date))
                send_notification = true
                frequency_word = 'today'
                stats = user.stats
            end
        elsif notification_frequency.downcase == 'weekly'
            if Date.today.wday == 1 && (last_notification.nil? || (Date.today.year > last_notification.created_at.year) || (Date.today.strftime("%V").to_i > last_notification.created_at.to_date.strftime("%V").to_i))
                send_notification = true
                frequency_word = 'this week'
                stats = user.stats
            end
        elsif notification_frequency.downcase == 'monthly'
            if Date.today.wday == 1 && (last_notification.nil? || (Date.today.year > last_notification.created_at.year) || (Date.today.month > last_notification.created_at.month))
                send_notification = true
                frequency_word = 'this month'
                stats = user.stats
            end
        end

        if send_notification
            number_of_expiring_connections = user.notifications.where("notification_type ilike ? and expiry_date >= ?","connection_expiration",Date.today).length
            unless SentEmail.where(user_id:user.id,sent_date:Date.today,source:"send_external_notifications_for").length > 0
                SystemMailer.expiring_connections_notification(number_of_expiring_connections,user,frequency_word).deliver 
                SentEmail.create(user_id:user.id,sent_date:Date.today,allowable_frequency:"daily",source:"send_external_notifications_for")
            end
        end
    end

end
