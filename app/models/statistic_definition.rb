class StatisticDefinition < ActiveRecord::Base
    has_many :user_statistics

    def self.triggers(operation_type,operation_trigger,current_user)
        statistics_to_be_triggered = StatisticDefinition.where("operation_type = ? AND operation_trigger ilike ?", operation_type, "%#{operation_trigger}%")
        if statistics_to_be_triggered.blank? 
            true
        else
            statistics_to_be_triggered.each do |statistic|
                begin
                    user_id = current_user.id
                    command = statistic.definition
                    eval(command)
                rescue => error
                    puts error.message
                    false
                else
                    true
                end
            end
        end
    end

end
