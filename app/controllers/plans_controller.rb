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
            actions = [{action:"popup_refresh_main_on_close",url:"http://localhost:3000/auth/google_calendar"},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Please connect Sphere with your Google Calendar in the popup"
        elsif connection.email.blank? && notify
            actions = [{action:"unhide",element:".modalView#makePlan input[name=connection_email]"},{action:"change_css",element:".modalView#makePlan input[name=connection_email]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"480"}}]
            status = false
            message ="Please enter an email for #{connection.first_name} as we don't seem to have it"
        elsif Chronic.parse(date).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=date]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your date input of '#{date}'. Try something esle"
        elsif Chronic.parse(time).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=time]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your time input of '#{time}'. Try something esle"
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

            if result[:access_token]
                session[:access_token] = result[:access_token][:access_token]
                session[:expires_at] = result[:access_token][:expires_at]
            end
            status = result[:status]
            message= result[:message]
            actions = [{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions}
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
            actions = [{action:"popup_refresh_main_on_close",url:"http://localhost:3000/auth/google_calendar"},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Please connect Sphere with your Google Calendar in the popup"
        elsif connection.email.blank? && notify
            actions = [{action:"unhide",element:".modalView#makePlan input[name=connection_email]"},{action:"change_css",element:".modalView#makePlan input[name=connection_email]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"480"}}]
            status = false
            message ="Please enter an email for #{connection.first_name} as we don't seem to have it"
        elsif Chronic.parse(date).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=date]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your date input of '#{date}'. Try something esle"
        elsif Chronic.parse(time).nil?
            actions = [{action:"change_css",element:".modalView#makePlan input[name=time]",css:{attribute:"border",value:"1px solid red"}},{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
            status = false
            message = "Oops. Our robot can't seem to understand your time input of '#{time}'. Try something esle"
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
            status = result[:status]
            message= result[:message]
            actions = [{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions}
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
        status = result[:status]
        message= result[:message]
        actions = [{action:"change_css",element:".remodal.standardModal",css:{attribute:"height",value:"450"}},{action:"function_call",function:"closeModalInstance(2000)"}]

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions}
          } 
        end

    end 

end
