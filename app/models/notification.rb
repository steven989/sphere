class Notification < ActiveRecord::Base
    validate :validate_data_type 
    belongs_to :user
    belongs_to :connection
    belongs_to :notifiable, polymorphic: true

    # Auto task
    def self.destroy_expired_notifications
        Notification.where("expiry_date < ? and one_time_display=false", Date.today).destroy_all # this will delete the notification the night immediately AFTER the expiry date specified
    end

    def showed_one_time_notification
      self.update_attributes(one_time_display:false)
    end

    # This is a user-level notification
    def self.create_new_level_notification(user,old_level,new_level,expiry_days=1,date=Date.today)
        # 1) Destroy any existing notifications
        Notification.where(user_id:user.id,notification_type:"level_up").destroy_all
        Notification.mark_all_one_time_notifications_as_read(user)
        # 2) Create a notification
        result = Notification.create(
          user_id: user.id,
          notification_type:"level_up",
          notification_date:date,
          expiry_date:date+expiry_days.day,
          data_type:"hash",
          value:"{old_level:#{old_level},new_level:#{new_level}}",
          one_time_display:true
          )
    end

    def self.mark_all_one_time_notifications_as_read(user)
        user.notifications.where(one_time_display:true).each do |notification|
          notification.update_attributes(one_time_display:false)
        end
    end

    # This is a user-level notification
    def self.create_new_badge_notification(user_badge,expiry_days=1,date=Date.today)
        # 1) Destroy any existing notifications
        user_badge.notifications.where(notification_type:"new_badge").destroy_all
        # 2) Create a notification
        user_badge.notifications.create(
          user_id: user_badge.user.id,
          notification_type:"new_badge",
          notification_date:date,
          expiry_date:date+expiry_days.day,
          data_type:"hash",
          value:"{badge_id:#{user_badge.badge.id}}"
          )
    end

    # This is a user-level notification
    def self.create_one_time_badge_notification(user,number_of_badges)
        Notification.mark_all_one_time_notifications_as_read(user)
        Notification.create(
          user_id:user.id,
          notification_type:'new_badges_one_time',
          notification_date:Date.today,
          expiry_date:Date.today,
          data_type:"integer",
          value:number_of_badges,
          one_time_display:true
        )
    end

    # This is a user-level notification
    def self.create_new_challenge_notification(user_challenge,expiry_days=1,date=Date.today)
        # 1) Destroy any existing notifications
        user_challenge.notifications.where(notification_type:"new_challenge").destroy_all
        # 2) Create a notification
        user_challenge.notifications.create(
          user_id: user_challenge.user.id,
          notification_type:"new_challenge",
          notification_date:date,
          expiry_date:date+expiry_days.day,
          data_type:"hash",
          value:"{challenge_id:#{user_challenge.challenge.id}}"
          )        
    end


    # This is a connection-level notification
    def self.create_expiry_notification(user,connection,expiry_date,remaining_days_until_expiry)
        # 1) Destroy any existing expiry notifications
        connection.notifications.where(user_id:user.id,notification_type:"connection_expiration").destroy_all
        # Notification.where(user_id:user.id,connection_id:connection.id,notification_type:"connection_expiration").destroy_all
        # 2) Create a notification
        connection.notifications.create(
          user_id: user.id,
          notification_type:"connection_expiration",
          notification_date:Date.today,
          expiry_date:expiry_date,
          data_type:"hash",
          value:"{remaining_days_until_expiry:#{remaining_days_until_expiry}}",
          priority: 2
          )
    end

    # This is a connection-level notification
    def self.create_checked_in_notification(user,connection,expiry_days=3,date=Date.today)
        # 1) Destroy any existing notifications
        connection.notifications.where(user_id:user.id,notification_type:"checked_in").destroy_all
        # Notification.where(user_id:user.id,connection_id:connection_id,notification_type:"checked_in").destroy_all
        # 2) Create a notification
        connection.notifications.create(
          user_id: user.id,
          notification_type:"checked_in",
          notification_date:date,
          expiry_date:date+expiry_days.days,
          priority: 3
          )
    end

    # This is a connection-level notification
    def self.create_upcoming_plan_notification(user,connection,date=Date.today)
        # 1) Destroy any existing notifications
        connection.notifications.where(user_id:user.id,notification_type:"upcoming_plan").destroy_all
        # Notification.where(user_id:user.id,connection_id:connection.id,notification_type:"upcoming_plan").destroy_all
        # 2) See if there are upcoming plans, if there are, then create. Otherwise do nothing
        plans = connection.plans.upcoming.order(date: :asc)
        if plans.length > 0 
          plan = plans.limit(1).take
          connection.notifications.create(
            user_id: user.id,
            notification_type:"upcoming_plan",
            notification_date:date,
            expiry_date:plan.date,
            data_type:"hash",
            value:"{plan_id:#{plan.id}}",
            priority: 1
            )
        end
    end

    def self.delete_all_expired_notifications
        Notification.where{ expiry_date < Date.today }.destroy_all
    end


    def update_value(value)
        self.update_attributes(value:value)
        self
    end

    def update_hash_value(values)
        if self.value_in_specified_type.class != Hash 
            false
        else
            total_value_old = self.value_in_specified_type
            values.each { |key,value| total_value_old[key] = value }
            self.update_value(total_value_old.to_s)
            self
        end
    end

    def delete_hash_key(key)
        if self.value_in_specified_type.class != Hash 
            false
        else
            total_value_old = self.value_in_specified_type
            total_value_old.delete(key.to_sym)
            self.update_value(total_value_old.to_s)
            self
        end        
    end


    def validate_data_type
        begin
          if self.data_type
            if self.data_type.downcase == 'hash'
                value_class = eval(self.value).class 
                result = value_class == Hash
            elsif self.data_type.downcase == 'array'
                value_class = eval(self.value).class 
                result = value_class == Array
            elsif self.data_type.downcase == 'integer'
                value_class = self.value.to_i.class 
                result = value_class == Fixnum
            else
                result = true
            end
          else
            result = true
          end
        rescue => error
            errors.add(:value,error.message)
        else 
            unless result
                errors.add(:value,"Specified type is #{self.data_type} but value is of type #{value_class}")
            end
        end
    end

    def value_in_specified_type
      if self.data_type
        if self.data_type.downcase == 'hash'
            result = eval(self.value)
        elsif self.data_type.downcase == 'array'
            result = eval(self.value)
        elsif self.data_type.downcase == 'integer'
            result = self.value.to_i
        else
            result = self.value
        end
      else
        result = self.value
      end
        result
    end

end
