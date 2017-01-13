class ChallengesController < ApplicationController
    before_action :require_login

    def start
        if user_challenge = current_user.user_challenges.where(challenge_id:params[:challenge_id]).take
            if user_challenge.belongs_to?(current_user)
                user_challenge.start_challenge
                status = true
                message = "Good luck! Mark complete when you're done"
                actions = [{action:"function_call",function:"afterStart($('.challengeCard[data-id=#{params[:challenge_id]}]'))"}]
                data = {days_remaining:user_challenge.date_to_be_completed - Date.today,status:"progressing"}
            else
                status = false
                message = "You do not have access to this challenge"
                actions = nil
                data = nil
            end
        else
            status = false
            message = "Oops. Our robots couldn't find this challenge. Please let us know"
            actions = nil
            data = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:status,message:message,actions:actions,data:data}
          } 
        end
    end

    def mark_complete
        user_challenge = current_user.user_challenges.where(challenge_id:params[:challenge_id]).take
        if user_challenge.belongs_to?(current_user)
            result = user_challenge.complete_challenge("completed")
            if result[:status]
                status = true
                if result[:reward]
                    message = "Nice job! +#{result[:reward]} points"
                else
                    message = "Challenge completed!"
                end
                actions = [{action:"function_call",function:"afterComplete($('.challengeCard[data-id=#{params[:challenge_id]}]'))"}]
            else
                status = false
                message = "Oops! Our robots ran into some issues"
                actions = nil
            end
        else
            status = false
            message = "You do not have access to this challenge"
            actions = nil
            data = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:true,message:message,actions:actions}
          } 
        end        
    end

    private
    def require_login
        redirect_to login_path if !logged_in?
    end    

end
