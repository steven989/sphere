class UserRemindersController < ApplicationController
    before_action :require_login

    def create
        if !params[:reminder].blank?
            if user_reminder = current_user.user_reminders.create(
                                connection_id:params[:connection_id],
                                reminder:params[:reminder],
                                status:"set",
                                due_date:params[:due_date].to_date
                            )
                Notification.create_reminder_notification(current_user,user_reminder)
                notifications = current_user.get_notifications(false)
                status = true
                message = "Reminder set! A blue bell will appear over your connection when the due date approaches"
                data = {user_reminder_id:user_reminder.id,due_date:user_reminder.due_date_humanized(current_user.timezone ? TZInfo::Timezone.get(current_user.timezone) : TZInfo::Timezone.get('America/New_York')),notifications:notifications}
                actions = [{action:"function_call",function:"setReminderCallback()"},{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"}]
            else
                status = false
                message = "Could not set reminder: #{user_reminder.errors.full_messages.join(', ')}"
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
