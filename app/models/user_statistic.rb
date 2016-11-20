class UserStatistic < ActiveRecord::Base
    belongs_to :user
    belongs_to :statistic_definition
    scope :find_statistic, ->(statistic_name) { where(name: statistic_name) }
end
