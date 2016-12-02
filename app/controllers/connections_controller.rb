class ConnectionsController < ApplicationController

    def create_note
        ConnectionNote.create(user_id:current_user.id,connection_id:params[:id],notes:params[:notes])
        redirect_to :root 
    end

    def update
        connection = Connection.find(params[:connection_id])
        photo_uploaded = !((params[:photo] == "undefined") || (params[:photo] == "null") || params[:photo].blank?)
        if photo_uploaded
            connection.remove_photo!
            connection.save
            connection.photo = params[:photo]
        end
        connection.assign_attributes(
            id:params[:connection_id]
        )
        if connection.save
            connection.update_attributes(photo_access_url:connection.photo.url) if photo_uploaded
            status = true
            message = "Connection successfully updated"
        else
            status = false
            message = "Connection could not be updated #{connection.errors.full_messages.join(', ')}"
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message}
          } 
        end

    end

    def import
        provider = params[:provider]
        if !current_user.authorized_by(provider,"contacts")
            actions = [{action:"popup_refresh_main_on_close",url:"http://localhost:3000/auth/google_contacts"}]
            status = false
            message = "Please connect Sphere with your Google Contacts in the popup"
            data=nil
        else
            access_token = session ? session[:access_token] : nil
            expires_at = session ? session[:expires_at] : nil
            result = Connection.import_from_google(current_user,access_token,expires_at)
            data = result[:data]
            status = result[:status]
            message = result[:message]
            if result[:access_token]
                session[:access_token] = result[:access_token][:access_token]
                session[:expires_at] = result[:access_token][:expires_at]
            end
            actions=[{action:"transitionViews",from:"[data-remodal-id=importModal] .modalView#mainImportView",to:"[data-remodal-id=importModal] .modalView#listSelect"},{action:"function_call",function:"populateImportSelectionList(returnedData)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end
    end

    def create_from_import
        result = Connection.create_from_import(current_user,params[:contactsToImport].values)
        actions = [{action:"function_call",function:"closeModalInstance(2000)"}]
        message = result[:status] ? result[:message] : "Oops. Looks like our robots had some errors saving the contacts. Here are the details: #{result[:message]}"

        respond_to do |format|
          format.json {
            render json: {status:result[:status], message:message,actions:actions,data:result[:data]}
          } 
        end
    end


    def populate_connection_modal

        data = {}
        connection = Connection.find(params[:connection_id])
        data[:photo] = connection.photo_url
        data[:name] = connection.name
        last_plan = Plan.last(current_user,connection)

        if last_plan
            last_plan_time_string = last_plan.last_activity_date_difference_humanized
            last_plan_name_string = last_plan.name_with_parentheses_removed
            data[:lastPlanString] = "Last Hangout: #{last_plan_time_string} #{last_plan_name_string}"
        else
            data[:lastPlanString] = "Last Hangout: Nothing yet!"
        end

        upcoming_plan = Plan.first_upcoming(current_user,connection)
        if upcoming_plan
            activity = upcoming_plan.name_with_parentheses_removed
            time = upcoming_plan.datetime_humanized
            data[:upcomingPlanString] = "#{activity} #{time}"
        else
            data[:upcomingPlanString] = "No current plans :("
        end
        actions= [{action:"function_call",function:"populateBubblesModal()"}]
        respond_to do |format|
          format.json {
            render json: {status:true, message:nil,actions:actions,data:data}
          } 
        end        
    end


end
