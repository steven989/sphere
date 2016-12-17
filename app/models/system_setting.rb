class SystemSetting < ActiveRecord::Base
    validate :validate_setting_data_type 
    validates :name, uniqueness: true

    def self.search(name)
        SystemSetting.where(name:name).take
    end

    def update_value(value)
        self.update_attributes(value:value.to_s)
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

    def validate_setting_name_uniqueness
        if SystemSetting.where(name:self.name) > 0 
            errors.add(:name,"There is already a setting by the name of #{self.name}")
        end
    end

    def self.update_system_setting(delete,id,name,data_type,value,description)
        if !id.blank?
            system_settingObj = SystemSetting.find(id)
            if system_settingObj
                if delete
                    system_settingObj.destroy
                    status = true
                    message = "System Setting deleted"
                    elements = nil
                else
                    # evaluate the criteria to make sure it's actually good
                    evaluation_result = SystemSetting.validate_setting_data_type(data_type,value)
                    if evaluation_result[:status]
                        system_settingObj.assign_attributes(name:name,data_type:data_type,value:value,description:description)
                        begin
                            savedObj = system_settingObj.save
                        rescue => error
                            status = false
                            message = "SystemSetting could not be updated: #{error.message}"
                            elements = nil                            
                        else
                            if savedObj
                                status = true
                                message = "System Setting successfully updated"
                                elements = nil
                            else
                                status = false
                                message = "System Setting could not be updated: #{system_settingObj.errors.full_messages.join(', ')}"
                                elements = system_settingObj.errors.messages.keys
                            end
                        end
                    else
                        status = false
                        message = evaluation_result[:message]
                        elements = nil
                    end
                end


            else
                status = true
                message = "Did not find ID. No action performed"
                elements = nil
            end 
        else
            # evaluate the criteria to make sure it's actually good
            evaluation_result = SystemSetting.validate_setting_data_type(data_type,value)
            if evaluation_result[:status]
                system_settingObj = SystemSetting.new(name:name,data_type:data_type,value:value,description:description)
                if system_settingObj.save
                    status = true
                    message = "System Setting successfully updated"
                    elements = nil
                else
                    status = false
                    message = "System Setting could not be updated: #{system_settingObj.errors.full_messages.join(', ')}"
                    elements = system_settingObj.errors.messages.keys
                end
            else
                status = false
                message = evaluation_result[:message]
                elements = nil
            end
        end
        {status:status,message:message,elements:elements}        
    end

    def validate_setting_data_type
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

    def self.validate_setting_data_type(data_type,value)
        begin
            if data_type.downcase == 'hash'
                value_class = eval(value).class 
                result = value_class == Hash
            elsif data_type.downcase == 'array'
                value_class = eval(value).class 
                result = value_class == Array
            elsif data_type.downcase == 'integer'
                value_class = value.to_i.class 
                result = value_class == Fixnum
            else
                result = true
            end
        rescue => error
            {status:false, message:error.message}
        else 
            {status:result,message:"#{result ? 'All good' : ('Data entered cannot be cast as '+data_type) }"}
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
