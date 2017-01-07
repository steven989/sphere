class UserSetting < ActiveRecord::Base
    belongs_to :user

    def self.create_from_system_settings(user)
        setting = UserSetting.create(value:SystemSetting.search('default_user_settings').value_in_specified_type)
        user.user_setting = setting
        setting
    end

    def get_new_settings_from_system_setting
        setting = SystemSetting.search('default_user_settings').value_in_specified_type
        current_user_settings = eval(self.value)
        setting.each do |key,value|
            current_user_settings[key.to_sym] = value if current_user_settings[key.to_sym].nil?
        end
        self.update_value(current_user_settings)
    end

    def get_value(key)
        value_evaled[key.to_sym]
    end

    def update_value(value)
        self.update_attributes(value:value.to_s)
        self
    end

    def update_hash_value(values)
        total_value_old = self.value_evaled
        values.each { |key,value| total_value_old[key] = value }
        self.update_value(total_value_old.to_s)
        self
    end

    def delete_hash_key(key)
        total_value_old = self.value_evaled
        total_value_old.delete(key.to_sym)
        self.update_value(total_value_old.to_s)
        self       
    end

    def value_evaled
        eval(self.value)
    end
end
