class Challenge < ActiveRecord::Base
    has_many :user_challenges
    has_many :current_users, through: :user_challenges, class_name: "User", foreign_key: "user_id", source: :user
    has_many :completed_users, through: :user_challenge_completeds, class_name: "User", foreign_key: "user_id", source: :user
end
