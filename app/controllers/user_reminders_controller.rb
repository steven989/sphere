class UserRemindersController < ApplicationController
    before_action :require_login

    def create
        if user_reminder = current_user.user_reminders.create(
                            connection_id:params[:connection_id],
                            reminder:params[:reminder],
                            status:"set",
                            due_date:params[:due_date].to_date
                        )
            status = true
            message = "Reminder set!"
            data = nil
            actions = [] #insert the reminder, clear and shift the box, make the modal taller, add height adjustment property to the preferences tab button
        else
            status = false
            message = "Could not set reminder: #{user_reminder.errors.full_messages.join(', ')}"
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
                user_reminder.update_attributes(status:"removed")
                status = true
                message = "Reminder removed!"
                data = nil
                actions = [] #remove the reminder, shift the box, make the modal shorter, add height adjustment property to the preferences tab button
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
