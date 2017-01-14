class UserReminder < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection

    scope :set, -> { where(status:"set") }
    scope :removed, -> { where(status:"removed") }

    def belongs_to?(user)
        self.user == user
    end

    def due_date_humanized(timezone)
        if self.due_date.blank?
            "No Due Date"
        else
            today_in_local_time = timezone.now.strftime("%Y-%m-%d").to_date
            difference = (self.due_date - today_in_local_time).to_i
            if difference < -1
                "#{difference} Days Overdue"
            elsif difference == -1
                "Due Yesterday"
            elsif difference == 0
                "Due Today"
            elsif difference == 1
                "Due Tomorrow"
            elsif difference > 1
                "Due in #{difference} days"
            end
        end
    end

end
