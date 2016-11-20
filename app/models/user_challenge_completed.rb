class UserChallengeCompleted < ActiveRecord::Base
    belongs_to :user
    belongs_to :challenge
    scope :repeated_allowed, ->(toggle) { where(repeated_allowed:toggle) } 
end
