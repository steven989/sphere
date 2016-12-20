class ActivityDefinition < ActiveRecord::Base
    has_many :activities
    scope :level, -> (level) { where(specificity_level:level) }

    def self.update_activity_definition(delete,id,activity,specificity_level,point_shared_experience_one_to_one,point_shared_experience_group_private,point_shared_experience_group_public,point_provide_help,point_receive_help,point_provide_gift,point_receive_gift,point_shared_outcome,point_shared_challenge,point_communication_digital,point_communication_in_person,point_shared_interest,point_intimacy)
        if !id.blank?
            activity_definitionObj = ActivityDefinition.find(id)
            if activity_definitionObj
                if delete
                    activity_definitionObj.destroy
                    status = true
                    message = "Activity Definition deleted"
                    elements = nil
                else
                    activity_definitionObj.assign_attributes(activity:activity,specificity_level:specificity_level,point_shared_experience_one_to_one:point_shared_experience_one_to_one,point_shared_experience_group_private:point_shared_experience_group_private,point_shared_experience_group_public:point_shared_experience_group_public,point_provide_help:point_provide_help,point_receive_help:point_receive_help,point_provide_gift:point_provide_gift,point_receive_gift:point_receive_gift,point_shared_outcome:point_shared_outcome,point_shared_challenge:point_shared_challenge,point_communication_digital:point_communication_digital,point_communication_in_person:point_communication_in_person,point_shared_interest:point_shared_interest,point_intimacy:point_intimacy)
                    begin
                        savedObj = activity_definitionObj.save
                    rescue => error
                        status = false
                        message = "Activity Definition could not be updated: #{error.message}"
                        elements = nil
                    else
                        if savedObj
                            status = true
                            message = "Activity Definition successfully updated"
                            elements = nil
                        else
                            status = false
                            message = "Activity Definition could not be updated: #{activity_definitionObj.errors.full_messages.join(', ')}"
                            elements = activity_definitionObj.errors.messages.keys
                        end
                    end
                end
            else
                status = true
                message = "Did not find ID. No action performed"
                elements = nil
            end 
        else
            activity_definitionObj = ActivityDefinition.new(activity:activity,specificity_level:specificity_level,point_shared_experience_one_to_one:point_shared_experience_one_to_one,point_shared_experience_group_private:point_shared_experience_group_private,point_shared_experience_group_public:point_shared_experience_group_public,point_provide_help:point_provide_help,point_receive_help:point_receive_help,point_provide_gift:point_provide_gift,point_receive_gift:point_receive_gift,point_shared_outcome:point_shared_outcome,point_shared_challenge:point_shared_challenge,point_communication_digital:point_communication_digital,point_communication_in_person:point_communication_in_person,point_shared_interest:point_shared_interest,point_intimacy:point_intimacy)
            begin 
                savedObj = activity_definitionObj.save
            rescue => error
                status = false
                message = "Activity Definition could not be updated: #{error.message}"
                elements = nil                
            else
                if savedObj
                    status = true
                    message = "ActivityDefinition successfully updated"
                    elements = nil
                else
                    status = false
                    message = "ActivityDefinition could not be updated: #{activity_definitionObj.errors.full_messages.join(', ')}"
                    elements = activity_definitionObj.errors.messages.keys
                end
            end

        end
        {status:status,message:message,elements:elements}        
    end
end
