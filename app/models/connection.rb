class Connection < ActiveRecord::Base
    belongs_to :user
    has_many :activities

    def name
        first_name+" "+last_name
    end
    
end
