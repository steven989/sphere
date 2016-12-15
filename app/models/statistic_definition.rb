class StatisticDefinition < ActiveRecord::Base
    has_many :user_statistics

    def start_value_in_type
        if self.start_value_type.blank?
            result = self.value
        elsif self.start_value_type.downcase == 'hash'
            result = eval(self.value)
        elsif self.start_value_type.downcase == 'array'
            result = eval(self.value)
        elsif self.start_value_type.downcase == 'integer'
            result = self.value.to_i
        elsif self.start_value_type.downcase == 'float'
            result = self.value.to_f
        else
            result = self.value
        end
        result        
    end

    def self.new_user_base_statistics(user)
        StatisticDefinition.all.each do |stat|
            user.user_statistics.create(
                statistic_definition_id:stat.id,
                name:stat.name,
                data_type:stat.start_value_type,
                value:stat.start_value
            )
        end
    end

    def self.triggers(operation_type,operation_trigger,current_user)
        statistics_to_be_triggered = StatisticDefinition.where("operation_type = ? AND operation_trigger ilike ?", operation_type, "%#{operation_trigger}%").order(priority: :desc)
        if statistics_to_be_triggered.blank? 
            true
        else
            statistics_to_be_triggered.each do |statistic|
                begin
                    user_id = current_user.id
                    statistic_definition_id = statistic.id
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
