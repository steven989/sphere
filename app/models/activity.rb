class Activity < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection
    belongs_to :activity_definition

    def self.create_activity(user,connection_id,activity_definition_id,date,initiator,notes=nil)
        if notes.blank?
            parsed_reminders_array = []
            reminder_stripped_notes = nil
        else
            regex_pattern = /\\+\s*remind\s*\(([^\\+]+)\)/i
            notes_parsing_result = notes.scan(regex_pattern)
            parsed_reminders_array = notes_parsing_result.map {|result| result[0]}
            if parsed_reminders_array.length > 0
                reminder_stripped_notes = notes.gsub(/\\+\s*remind\s*\([^\\+]+\)/i,"").strip
            else
                reminder_stripped_notes = notes.strip
            end
        end
        activity = user.activities.new(connection_id:connection_id,activity_definition_id:activity_definition_id,date:date,initiator:initiator,notes:reminder_stripped_notes)
        if activity.save
            if parsed_reminders_array.length > 0
                parsed_reminders_array.each do |reminder|
                    UserReminder.create_reminder(user,connection_id,reminder,"")
                end
                AppUsage.log_action("Added reminder through check-in notes",user)
            end
            activity.update_attributes(activity:ActivityDefinition.find(activity_definition_id).activity)
            connection = Connection.find(connection_id)
            result = connection.update_score
            connection.update_attributes(active:true,times_degraded:0)
            StatisticDefinition.triggers("individual","create_activity",User.find(user.id))
            Notification.create_checked_in_notification(user,connection)
            connection.notifications.where(notification_type:"connection_expiration").destroy_all
            status = true
            message = "Activity created"
            data = {quality_score_gained:result[:quality_score_gained]}
        else
            status = false
            message = "#{activity.errors.full_messages.joing(', ')}"
            data = nil
        end
        {status:status,message:message,data:data}
    end
    
end
