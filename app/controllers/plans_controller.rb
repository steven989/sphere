class PlansController < ApplicationController
    before_action :require_login

    def create
        date = params[:date]
        start_time = params[:timeFrom]
        end_time = params[:timeTo]
        summary = params[:name]
        location = params[:location]
        details = params[:details]
        put_on_google = params[:putOnGoogle].blank? ? false : (params[:putOnGoogle] == "true"? true : false)
        notify = params[:notify].blank? ? false : (params[:notify] == "true"? true : false)
        connection_email = params[:connection_email]

        unless params[:connection_id] == 0
            connection = Connection.find(params[:connection_id])
            summary+=" (with #{connection.name})"
        end

        if !connection_email.blank? && connection.email.blank?
            connection.update_attributes(email:connection_email)
        end

        if connection.email.blank? && notify && put_on_google
            actions = [{action:"unhide",element:".modalView#makePlan .formElement.email"},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"430"}}]
            status = false
            message ="Please enter an email for #{connection.first_name} as we don't seem to have it"
            data = nil
        elsif Chronic.parse(date).nil?
            actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.date"}]
            status = false
            message = "Oops. Our robot can't seem to understand your date input of '#{date}'. Try something else"
            data = nil
        elsif Chronic.parse(start_time).nil?
            actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.timeFrom"}]
            status = false
            message = "Oops. We can't seem to understand your time input of '#{start_time}'. Try something else"
            data = nil
        elsif Chronic.parse(end_time).nil?
            actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan  .formElement.timeTo"}]
            status = false
            message = "Sorry! We can't seem to understand your time input of '#{end_time}'. Try something else"
            data = nil
        elsif Chronic.parse(end_time) - Chronic.parse(start_time) < 0
            actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.timeFrom"},{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.timeTo"}]
            status = false
            message = "End time can't be before start time! Try again"
            data = nil            
        else
            access_token = session ? session[:access_token] : nil
            expires_at = session ? session[:expires_at] : nil            
            result = Plan.create_event(current_user,
                                        {   date:date,
                                            start_time:start_time,
                                            end_time:end_time,
                                            summary:summary,
                                            location:location,
                                            details:details,
                                            notify:notify
                                        },
                                       connection,
                                       connection_email,
                                       access_token,
                                       expires_at,
                                       "primary",
                                       put_on_google
                                    )

            status = result[:status]
            if status
                if result[:access_token]
                    session[:access_token] = result[:access_token][:access_token]
                    session[:expires_at] = result[:access_token][:expires_at]
                end
                Notification.create_upcoming_plan_notification(current_user,connection)
                notifications = current_user.get_notifications(false)
                new_stats = current_user.stats
                data = {notifications:notifications,new_stats:new_stats}
                message= result[:message]
                actions = [{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"},{action:"function_call",function:"updateRealTimeStats(returnedData.new_stats)"},{action:"function_call",function:"updateUserLevelNotifications(returnedData.notifications.user_level)"},{action:"function_call",function:"closeModalInstance(100)"}]
            elsif !status && (result[:message].downcase.include?("unauthorize") || result[:message].downcase.include?("permission") || result[:message].downcase.include?("insufficient"))
                message = "Hmm looks like we don't have access to your Google calendar. Click on the import button again to connect your Google account!"
                scope = current_user.authorizations.where(provider:'google').take.scope_value
                scope.reject! {|s| s == "calendar"}
                current_user.authorizations.where(provider:'google').take.update_scope(scope)
                session[:access_token] = nil
                session[:expires_at] = nil
                actions = [{action:"function_call",function:"changeVariableValue('authorized_google_calendar',false)"}]
            else
                message = "Uh oh. There seems to be some issues: #{result[:message]}"
            end
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end
    end

    def update
        date = params[:date]
        start_time = params[:timeFrom]
        end_time = params[:timeTo]
        summary = params[:name]
        location = params[:location]
        details = params[:details]
        put_on_google = params[:putOnGoogle].blank? ? false : (params[:putOnGoogle] == "true"? true : false)
        notify = params[:notify].blank? ? false : (params[:notify] == "true"? true : false)
        connection_email = params[:connection_email]

        unless params[:connection_id] == 0
            connection = Connection.find(params[:connection_id])
            summary+=" (with #{connection.name})"
        end

        plan = Plan.find(params[:plan_id])
        if plan.belongs_to?(current_user)
            if !connection_email.blank? && connection.email.blank?
                connection.update_attributes(email:connection_email)
                summary+=" (with #{connection.name})"
            end

            if connection.email.blank? && notify && put_on_google
                actions = [{action:"unhide",element:".modalView#makePlan .formElement.email"},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"430"}}]
                status = false
                message ="Please enter an email for #{connection.first_name} as we don't seem to have it"
                data = nil
            elsif Chronic.parse(date).nil?
                actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.date"}]
                status = false
                message = "Oops. Our robot can't seem to understand your date input of '#{date}'. Try something else"
                data = nil
            elsif Chronic.parse(start_time).nil?
                actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.timeFrom"}]
                status = false
                message = "Oops. We can't seem to understand your time input of '#{start_time}'. Try something else"
                data = nil
            elsif Chronic.parse(end_time).nil?
                actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan  .formElement.timeTo"}]
                status = false
                message = "Sorry! We can't seem to understand your time input of '#{end_time}'. Try something else"
                data = nil
            elsif Chronic.parse(end_time) - Chronic.parse(start_time) < 0
                actions = [{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.timeFrom"},{action:"add_class",class:"errorFormInput",element:".modalView#makePlan .formElement.timeTo"}]
                status = false
                message = "End time can't be before start time! Try again"
                data = nil
            else
                access_token = session ? session[:access_token] : nil
                expires_at = session ? session[:expires_at] : nil 
                result = plan.update_event(current_user,
                                            {   date:date,
                                                start_time:start_time,
                                                end_time:end_time,
                                                summary:summary,
                                                location:location,
                                                details:details,
                                                notify:notify
                                            },
                                           connection,
                                           connection_email,
                                           access_token,
                                           expires_at,
                                           put_on_google
                                        )

                status = result[:status]
                message= result[:message]

                if status
                    if result[:access_token]
                        session[:access_token] = result[:access_token][:access_token]
                        session[:expires_at] = result[:access_token][:expires_at]
                    end
                    Notification.create_upcoming_plan_notification(current_user,connection)
                    notifications = current_user.get_notifications(false)
                    data = {notifications:notifications}
                    message= result[:message]
                    actions = [{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"},{action:"function_call",function:"closeModalInstance(100)"}]
                elsif !status && result[:message].include?("Unauthorize")
                    message = "Hmm looks like we don't have access to your Google calendar. Click on the import button again to connect your Google account!"
                    scope = current_user.authorizations.where(provider:'google').take.scope_value
                    scope.reject! {|s| s == "calendar"}
                    current_user.authorizations.where(provider:'google').take.update_scope(scope)
                    session[:access_token] = nil
                    session[:expires_at] = nil
                    actions = [{action:"function_call",function:"changeVariableValue('authorized_google_calendar',false)"}]
                else
                    message = "Uh oh. There seems to be some issues: #{result[:message]}"
                end            
            end
        else
            status = false
            message = "You do not have access to this activity"
            actions = nil
            data = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end
    end

    def cancel
        plan = Plan.find(params[:plan_id])
        if plan.belongs_to?(current_user)
            notify = params[:notify].blank? ? false : (params[:notify] == "true"? true : false)
            if plan.connection.email.blank? && notify
                actions = [{action:"unhide",element:".modalView#makePlan .formElement.email"},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"430"}}]
                status = false
                message ="Please enter an email for #{plan.connection.first_name} as we don't seem to have it"
                data = nil
            else
                access_token = session ? session[:access_token] : nil
                expires_at = session ? session[:expires_at] : nil 
                result = plan.delete_event(params[:notify],access_token,expires_at,true)
                if plan.connection
                    Notification.create_upcoming_plan_notification(current_user,plan.connection) 
                end
                if result[:access_token]
                    session[:access_token] = result[:access_token][:access_token]
                    session[:expires_at] = result[:access_token][:expires_at]
                end
                notifications = current_user.get_notifications(false)
                status = result[:status]
                message= result[:message]
                data = {notifications:notifications}
                actions = [{action:"function_call",function:"closeModalInstance(100)"},{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"}]
            end
        else
            status = false
            message = "You do not have access to this activity"
            actions = nil
            data = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end

    end 
    private
    
    def require_login
        redirect_to login_path if !logged_in?
    end

end
