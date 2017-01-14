class UserReminder < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection
    has_many :notifications, as: :notifiable

    scope :set, -> { where(status:"set") }
    scope :removed, -> { where(status:"removed") }

    def belongs_to?(user)
        self.user == user
    end

    def self.remove_all_overdue_reminders(grace_period)
        UserReminder.where("due_date < ?",Date.today - grace_period).each do |reminder|
            reminder.remove
        end
    end

    def remove
        self.update_attributes(status:"removed")
        self.user.notifications.where("notification_type = 'user_created_reminder' and value ilike ?", "%user_reminder_id%#{self.id}%").destroy_all        
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
