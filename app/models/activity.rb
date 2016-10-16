class Activity < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection
end
