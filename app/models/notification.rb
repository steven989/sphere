class Notification < ActiveRecord::Base
    validate :validate_data_type 
    belongs_to :user


    def self.create_expiry_notification(user_id,connection_id,expiry_date,remaining_days_until_expiry)
        # 1) Destroy any existing expiry notifications
        Notification.where(user_id:user_id,notification_type:"connection_expiration").each {|notification| notification.destroy if notification.value_in_specified_type[:connection_id].to_i == connection_id }
        # 2) Create a notification
        Notification.create(
          user_id: user_id,
          notification_type:"connection_expiration",
          notification_date:Date.today,
          expiry_date:expiry_date,
          data_type:"hash",
          value:"{connection_id:#{connection_id},remaining_days_until_expiry:#{remaining_days_until_expiry}}"
          )
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
        rescue => error
            errors.add(:value,error.message)
        else 
            unless result
                errors.add(:value,"Specified type is #{self.data_type} but value is of type #{value_class}")
            end
        end
    end

    def value_in_specified_type
        if self.data_type.downcase == 'hash'
            result = eval(self.value)
        elsif self.data_type.downcase == 'array'
            result = eval(self.value)
        elsif self.data_type.downcase == 'integer'
            result = self.value.to_i
        else
            result = self.value
        end
        result
    end

end
