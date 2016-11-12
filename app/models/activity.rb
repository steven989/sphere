class Activity < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection
    belongs_to :activity_definition

    
end
