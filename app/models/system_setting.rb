class SystemSetting < ActiveRecord::Base
    validate :validate_setting_data_type 
    validates :name, uniqueness: true

    def self.search(name)
        SystemSetting.where(name:name).take
    end

    def update_value(value)
        self.update_attributes(value:value)
    end

    def validate_setting_name_uniqueness
        if SystemSetting.where(name:self.name) > 0 
            errors.add(:name,"There is already a setting by the name of #{self.name}")
        end
    end

    def validate_setting_data_type
        begin
            if self.data_type == 'hash'
                value_class = eval(self.value).class 
                result = value_class == Hash
            elsif self.data_type == 'array'
                value_class = eval(self.value).class 
                result = value_class == Array
            elsif self.data_type == 'integer'
                value_class = self.value.to_i.class 
                result = value_class == Fixnum
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
        if self.data_type == 'hash'
            result = eval(self.value)
        elsif self.data_type == 'array'
            result = eval(self.value)
        elsif self.data_type == 'integer'
            result = self.value.to_i
        else
            result = self.value
        end
        result
    end
end
