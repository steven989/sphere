class UserStatistic < ActiveRecord::Base
    belongs_to :user
    belongs_to :statistic_definition
    scope :find_statistic, ->(statistic_name) { where(name: statistic_name.downcase) }

    def value_in_type
        if data_type == "integer"
            value.to_i
        elsif data_type == "float"
            value.to_f
        else
            value
        end
    end
end
