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
                eval(self.value)
            elsif self.data_type == 'array'
                eval(self.value)
            elsif self.data_type == 'integer'
                self.value.to_i
            end
        rescue => error
            errors.add(:value,error.message)
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
