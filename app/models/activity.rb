class Activity < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection
    belongs_to :activity_definition

    def self.create_activity(user,connection_id,activity_definition_id,date,initiator)
        activity = user.activities.new(connection_id:connection_id,activity_definition_id:activity_definition_id,date:date,initiator:initiator)
        if activity.save
            activity.update_attributes(activity:ActivityDefinition.find(activity_definition_id).activity)
            connection = Connection.find(connection_id)
            result = connection.update_score
            connection.update_attributes(active:true)
            StatisticDefinition.triggers("individual","create_activity",user)
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
