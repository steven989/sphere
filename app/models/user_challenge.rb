class UserChallenge < ActiveRecord::Base
    belongs_to :user
    belongs_to :challenge
    has_many :notifications, as: :notifiable

    def start_challenge
        days_to_complete = challenge.days_to_complete.blank? ? nil : challenge.days_to_complete
        self.update_attributes(
            status:"progressing",
            date_started:Date.today,
            date_to_be_completed:Date.today+days_to_complete.days
        )
        return true
    end

    def complete_challenge(method_of_completion)
        reward = method_of_completion == "completed" ? challenge.reward : nil
        if user.user_challenge_completeds.create(
            challenge_id:challenge.id,
            date_shown_to_user:date_shown_to_user,
            date_started:date_started,
            date_to_be_completed:date_to_be_completed,
            date_completed:Date.today,
            method_of_completion:method_of_completion,
            repeated_allowed:challenge.repeated_allowed,
            reward:reward
        );
            self.destroy
            self.notifications.destroy_all
            StatisticDefinition.triggers("individual","complete_challenge",User.find(user.id)) if reward
            status = true
            message = "Challenge completed"
        else
            status = false
            message = user_challenge_completeds.errors.full_messages.join(', ')
        end
        {status:status,message:message,reward:reward}
    end

    def self.expire_uncompleted_challenges
        UserChallenge.where("? > date_to_be_completed", Date.today).each do |user_challenge| 
            user_challenge.complete_challenge("expired")
        end
    end

end
