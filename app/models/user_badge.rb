class UserBadge < ActiveRecord::Base
    belongs_to :user
    belongs_to :badge
    has_many :notifications, as: :notifiable
    
end
