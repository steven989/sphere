class AppUsage < ActiveRecord::Base
    belongs_to :user

    def self.log_action(action,user,additional_info=nil)
        usage = AppUsage.new(
            user_id:user.id,
            action:action,
            additional_info:additional_info
        )
        if usage.save
            status = true
            message = nil
        else
            status = false
            usage.error.full_messages.join(', ')
        end
        {status:status,message:message}
    end

end
