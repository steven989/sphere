class UserReminder < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection

    scope :set, -> { where(status:"set") }
    scope :removed, -> { where(status:"removed") }

    def belongs_to?(user)
        self.user == user
    end
end
