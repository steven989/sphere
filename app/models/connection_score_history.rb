class ConnectionScoreHistory < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection

end
