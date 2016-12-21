class PlansController < ApplicationController

    def create
        date = params[:date]
        time = params[:time]
        duration = params[:duration]
        summary = params[:name]
        location = params[:location]
        details = params[:details]
        notify = params[:notify].blank? ? false : true
        connection_email = params[:connection_email]

        unless params[:connection_id] == 0
            connection = Connection.find(params[:connection_id])
            summary+=" (with #{connection.name})"
        end

        if !connection_email.blank? && connection.email.blank?
            connection.update_attributes(email:connection_email)
        end

        if !current_user.authorized_by("google","calendar")
            actions = [{action:"popup_refresh_main_on_close",url:"#{Rails.env.production? ? ENV['PRODUCTION_HOST_DOMAIN']+'auth/google_calendar' : 'http://localhost:3000/auth/google_calendar'}"},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Please connect Sphere with your Google Calendar in the popup"
            data = nil
        elsif connection.email.blank? && notify
            actions = [{action:"unhide",element:".modalView#makePlan input[name=connection_email]"},{action:"change_css",element:".modalView#makePlan input[name=connection_email]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"480"}}]
            status = false
            message ="Please enter an email for #{connection.first_name} as we don't seem to have it"
            data = nil
        elsif Chronic.parse(date).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=date]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your date input of '#{date}'. Try something esle"
            data = nil
        elsif Chronic.parse(time).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=time]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your time input of '#{time}'. Try something esle"
            data = nil
        else
            access_token = session ? session[:access_token] : nil
            expires_at = session ? session[:expires_at] : nil            
            result = Plan.create_event(current_user,
                                        {   date:date,
                                            time:time,
                                            duration:duration,
                                            summary:summary,
                                            location:location,
                                            details:details,
                                            notify:notify
                                        },
                                       connection,
                                       connection_email,
                                       access_token,
                                       expires_at,
                                       "primary"
                                    )

            status = result[:status]
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
            elsif !status && result[:message].include?("")
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
        time = params[:time]
        duration = params[:duration]
        summary = params[:name]
        location = params[:location]
        details = params[:details]
        notify = params[:notify].blank? ? false : true
        connection_email = params[:connection_email]

        unless params[:connection_id] == 0
            connection = Connection.find(params[:connection_id])
        end

        plan = Plan.find(params[:plan_id])

        if !connection_email.blank? && connection.email.blank?
            connection.update_attributes(email:connection_email)
            summary+=" (with #{connection.name})"
        end

        if !current_user.authorized_by("google","calendar")
            actions = [{action:"popup_refresh_main_on_close",url:"#{Rails.env.production? ? ENV['PRODUCTION_HOST_DOMAIN']+'auth/google_calendar' : 'http://localhost:3000/auth/google_calendar'}"},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Please connect Sphere with your Google Calendar in the popup"
            data = nil
        elsif connection.email.blank? && notify
            actions = [{action:"unhide",element:".modalView#makePlan input[name=connection_email]"},{action:"change_css",element:".modalView#makePlan input[name=connection_email]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"480"}}]
            status = false
            message ="Please enter an email for #{connection.first_name} as we don't seem to have it"
            data = nil
        elsif Chronic.parse(date).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=date]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your date input of '#{date}'. Try something esle"
            data = nil
        elsif Chronic.parse(time).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=time]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your time input of '#{time}'. Try something esle"
            data = nil
        else
            access_token = session ? session[:access_token] : nil
            expires_at = session ? session[:expires_at] : nil 
            result = plan.update_event(current_user,
                                        {   date:date,
                                            time:time,
                                            duration:duration,
                                            summary:summary,
                                            location:location,
                                            details:details,
                                            notify:notify
                                        },
                                       connection,
                                       connection_email,
                                       access_token,
                                       expires_at
                                    )

            if result[:access_token]
                session[:access_token] = result[:access_token][:access_token]
                session[:expires_at] = result[:access_token][:expires_at]
            end
            Notification.create_upcoming_plan_notification(current_user,connection)
            notifications = current_user.get_notifications(false)
            status = result[:status]
            message= result[:message]
            data = {notifications:notifications}
            actions = [{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end
    end

    def cancel
        plan = Plan.find(params[:plan_id])
        access_token = session ? session[:access_token] : nil
        expires_at = session ? session[:expires_at] : nil 
        result = plan.delete_event(params[:notify],access_token,expires_at)
        if result[:access_token]
            session[:access_token] = result[:access_token][:access_token]
            session[:expires_at] = result[:access_token][:expires_at]
        end
        if plan.connection
            Notification.create_upcoming_plan_notification(current_user,plan.connection) 
        end
        notifications = current_user.get_notifications(false)
        status = result[:status]
        message= result[:message]
        data = {notifications:notifications}
        actions = [{action:"function_call",function:"closeModalInstance(100)"},{action:"function_call",function:"prettifyBubbles($('#canvas'),returnedData.notifications)"}]

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end

    end 

end
