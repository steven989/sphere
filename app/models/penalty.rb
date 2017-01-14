class Penalty < ActiveRecord::Base
    belongs_to :user
    belongs_to :statistic_definition
    belongs_to :connection
end
