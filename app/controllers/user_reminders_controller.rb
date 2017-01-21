class UserRemindersController < ApplicationController
    before_action :require_login

    def create
        if !params[:reminder].blank?
            result = UserReminder.create_reminder(current_user,params[:connection_id],params[:reminder],params[:due_date])
            if result[:status]
                user_reminder=result[:data]
                message = result[:message]
                notifications = current_user.get_notifications(false)
                status = true
                data = {user_reminder_id:user_reminder.id,due_date:user_reminder.due_date_humanized(current_user.timezone ? TZInfo::Timezone.get(current_user.timezone) : TZInfo::Timezone.get('America/New_York')),notifications:notifications}
                actions = [{action:"function_call",function:"setReminderCallback()"},{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"}]
            else
                status = false
                message = result[:message]
                data = nil
                actions = nil
            end
        else
            status = false
            message = "Please enter the reminder text"
            data = nil
            actions = nil
        end

        respond_to do |format|
          format.json {
            render json: {status:status,message:message,actions:actions,data:data}
          } 
        end
    end

    def remove
        user_reminder = UserReminder.find(params[:user_reminder_id])
        if user_reminder
            if user_reminder.belongs_to?(current_user)
                user_reminder.remove
                notifications = current_user.get_notifications(false)
                status = true
                message = "Reminder removed!"
                data = {user_reminder_id:params[:user_reminder_id],notifications:notifications}
                actions = [{action:"function_call",function:"removeReminderCallback()"},{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"}]
            else
                status = false
                message = "You do not have access to this reminder"
                data = nil
                actions = nil
            end
        else
            status = false
            message = "Reminder not found!"
            data = nil
            actions = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:status,message:message,actions:actions,data:data}
          } 
        end
    end

    private
    def require_login
        redirect_to login_path if !logged_in?
    end
end
