class ConnectionsController < ApplicationController


    def create_note
        ConnectionNote.create(user_id:current_user.id,connection_id:params[:id],notes:params[:notes])
        redirect_to :root 
    end

    def update_name
        connection_id = params[:id]
        if !params[:value].blank?
            name = params[:value]
            first_name = Connection.parse_first_name(name)
            last_name = Connection.parse_last_name(name)
            connection = Connection.find(connection_id)
            connection.update_attributes(first_name:first_name,last_name:last_name)
            status = true
            message = "Name updated!"
            raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
            notifications = current_user.get_notifications(false)
            bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
            actions=[{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles)"}]
            data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
        else
            status = false
            message = nil
            actions = nil
            data = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:status,message:message,actions:actions,data:data}
          } 
        end        
    end

    def update_email
        connection_id = params[:id]
        if !params[:value].blank?
            connection = Connection.find(connection_id)
            if connection.update_attributes(email:params[:value])
                status = true
                message = "Email updated!"
                raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
                notifications = current_user.get_notifications(false)
                bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
                actions=[{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles)"}]
                data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
            else
                status = false
                message = connection.errors.full_messages.join(', ')
            end
        else
            status = false
            message = nil
            actions = nil
            data = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:status,message:message,actions:actions,data:data}
          } 
        end        
    end

    def update
        connection = Connection.find(params[:connection_id])
        photo_uploaded = !((params[:photo] == "undefined") || (params[:photo] == "null") || params[:photo].blank?)

        if params[:contact_frequency] == "other" && (params[:custom_frequency].blank? || params[:custom_frequency].to_i < 1 )
            status = false
            message = "Please enter a valid number of days"
            actions = [{action:"add_class",element:".modalView#editConnection input[name=other_days]",class:"errorFormInput"}]
        else
            if photo_uploaded
                connection.remove_photo!
                connection.save
                connection.photo = params[:photo]
            end
            target_contact_interval_in_days = (params[:contact_frequency] == "monthly" ? 30 : ( params[:contact_frequency] == "weekly" ? 7 : params[:custom_frequency].to_i ) )
            connection.assign_attributes(
                id:params[:connection_id],
                frequency_word:params[:contact_frequency],
                target_contact_interval_in_days:target_contact_interval_in_days,
                notes:params[:notes]
            )
            if connection.save
                Connection.port_photo_url_to_access_url(connection.id)
                status = true
                message = "Awesome. We updated #{connection.first_name}'s info for you!"
                actions = [{action:"function_call",function:"resetModal($('.modalView#editConnection  .modalContentContainer'),1)"},{action:"function_call",function:"closeModalInstance(100)"}]
                data = nil
                if photo_uploaded
                  raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
                  notifications = current_user.get_notifications(false)
                  bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
                  data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
                  actions.push({action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles)"})
                end
            else
                status = false
                message = "Oops. Our robots ran into some issues: #{connection.errors.full_messages.join(', ')}"
                actions = nil
                data = nil
            end
        end
        respond_to do |format|
          format.json {
            render json: {status:status,message:message,actions:actions,data:data}
          } 
        end
    end

    def list_expired_connections
        expired_connections = current_user.get_raw_bubbles_data(nil,false,false)
        actions = [{action:"function_call",function:"populateExpiredConnections()"}]
        respond_to do |format|
          format.json {
            render json: {status:true,message:nil,actions:actions,data:expired_connections}
          } 
        end        
    end

    def revive_expired_connections
        connection = Connection.find(params[:connection_id])
        result = connection.revive
        status = result[:status]
        message = result[:message]

        if result[:status]
            raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
            notifications = current_user.get_notifications(false)
            bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
            data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
            actions = [{action:"fadeDelete",element:"#expiredConnectionRow#{params[:connection_id]}",fadeoutTime:600},{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles)"}]
            if current_user.connections.expired.length == 0
                actions.push({action:"function_call",function:"putWordsBackInIfNoExpiredConnection(610)"}) 
                actions.push({action:"function_call",function:""})
            end
        else
            actions = nil
            data = nil
        end
        respond_to do |format|
          format.json {
            render json: {status:status,message:message,actions:actions,data:data}
          } 
        end
    end


    def import
        provider = params[:provider]
        # if !current_user.authorized_by(provider,"contacts")
        #     actions = [{action:"popup_refresh_main_on_close",url:"#{Rails.env.production? ? ENV['PRODUCTION_HOST_DOMAIN']+'auth/google_contacts' : 'http://localhost:3000/auth/google_contacts'}"}]
        #     status = false
        #     message = "Please connect Sphere with your Google Contacts in the popup"
        #     data=nil
        # else

            access_token = session ? session[:access_token] : nil
            expires_at = session ? session[:expires_at] : nil
            result = Connection.import_from_google(current_user,access_token,expires_at,"summarized_array")
            data = result[:data]
            status = result[:status]
            if status
                if result[:access_token]
                    session[:access_token] = result[:access_token][:access_token]
                    session[:expires_at] = result[:access_token][:expires_at]
                end
                message = result[:message]
                actions=[{action:"transitionViews",from:"[data-remodal-id=importModal] .modalView#mainImportView",to:"[data-remodal-id=importModal] .modalView#listSelect"},{action:"function_call",function:"populateImportSelectionList(returnedData)"}]
            elsif !status && result[:message].include?("Unauthorized")
                message = "Hmm looks like we don't have access to your #{provider.capitalize} contacts. Click on the import button again to connect your #{provider.capitalize} account!"
                scope = current_user.authorizations.where(provider:provider).take.scope_value
                scope.reject! {|s| s == "contacts"}
                current_user.authorizations.where(provider:provider).take.update_scope(scope)
                session[:access_token] = nil
                session[:expires_at] = nil
                actions = [{action:"function_call",function:"changeVariableValue('authorized_google_contacts',false)"}]
            else
                message = "Uh oh. There seems to be some issues: #{result[:message]}"
            end
            
        # end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end
    end

    def create_from_import
        access_token = session ? session[:access_token] : nil
        expires_at = session ? session[:expires_at] : nil
        merge_name = params[:mergeName].blank? ? nil : (params[:mergeName] == "true" ? true : false)
        result = Connection.create_from_import(current_user,params[:contactsToImport].values,access_token,expires_at,merge_name)

        if result[:status] 
          raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
          notifications = current_user.get_notifications(false)
          bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
          message = result[:message]
          actions=[{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles)"},{action:"function_call",function:"closeModalInstance(100)"}]
          data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
        else
          message = "Oops. Looks like our robots had some errors saving the contacts. Here are the details: #{result[:message]}"
          actions = nil
          data = result[:data]
        end

        respond_to do |format|
          format.json {
            render json: {status:result[:status], message:message,actions:actions,data:data}
          } 
        end
    end

    def destroy
       connection = Connection.find(params[:connection_id])
       connection.activities.destroy_all
       connection.connection_score.destroy if connection.connection_score
       connection.connection_score_histories.destroy_all
       connection.plans.destroy_all
       connection.notifications.destroy_all
       connection.tags.destroy_all
       connection.destroy
       redirect_to root_path
    end

    def destroy_all
        current_user.activities.destroy_all
        current_user.connection_scores.destroy_all
        current_user.connection_score_histories.destroy_all
        current_user.plans.destroy_all
        current_user.notifications.destroy_all
        current_user.tags.destroy_all
        current_user.connections.destroy_all
        current_user.user_challenges.destroy_all
        current_user.user_badges.destroy_all
        current_user.current_challenges.destroy_all
        current_user.user_statistics.find_statistic('xp').take.update_attributes(value:0)
        current_user.user_statistics.find_statistic('level').take.update_attributes(value:0)
        redirect_to root_path
    end

    def populate_connection_modal

        data = {}
        connection = Connection.find(params[:connection_id])
        date_of_last_activity_with_this_connection = connection.activities.where("activity not ilike '%added%to%sphere'").last && connection.activities.where("activity not ilike '%added%to%sphere'").order(:date).last.date
        check_in_button_state =  date_of_last_activity_with_this_connection.nil? || Date.today > date_of_last_activity_with_this_connection
        data[:connection_id] = params[:connection_id]
        data[:photo] = connection.photo_url
        data[:name] = connection.name
        data[:email] = connection.email
        data[:notes] = connection.notes
        data[:contact_frequency] = connection.frequency_word
        data[:target_contact_interval_in_days] = connection.target_contact_interval_in_days

        last_plan = Plan.last(current_user,connection)

        if last_plan
            last_plan_time_string = last_plan.last_activity_date_difference_humanized
            last_plan_name_string = last_plan.name_with_parentheses_removed
            data[:lastPlanString] = "Last Hangout: #{last_plan_time_string} #{last_plan_name_string}"
        else
            data[:lastPlanString] = "Last Hangout: Nothing yet!"
        end

        data[:connection_tags] = connection.tags.order(created_at: :asc).map {|tag| tag.tag}
        data[:all_tags] = current_user.tags.where(taggable_type:"Connection").order(tag: :asc).map {|tag| tag.tag}.uniq

        upcoming_plan = Plan.first_upcoming(current_user,connection)
        if upcoming_plan
            activity = upcoming_plan.name_with_parentheses_removed
            time = upcoming_plan.datetime_humanized
            data[:upcomingPlanString] = "#{activity} #{time}"
            data[:hasUpcomingPlan] = true
            data[:authorized_by_google_calendar] = current_user.authorized_by("google","calendar")
            data[:planData] = {id:upcoming_plan.id,date:upcoming_plan.date_time_in_zone('start_time','date'),start_time:upcoming_plan.date_time_in_zone('start_time','time'),end_time:upcoming_plan.date_time_in_zone('end_time','time'),name:upcoming_plan.name_with_parentheses_removed,location:upcoming_plan.location,details:upcoming_plan.details,notify:upcoming_plan.invite_sent}
        else
            data[:upcomingPlanString] = "No current plans :("
            data[:hasUpcomingPlan] = false
        end
        actions= [{action:"function_call",function:"populateBubblesModal()"},{action:"function_call",function:"checkInButtons('#{check_in_button_state}',{})"},{action:"function_call",function:"initializeReModal('[data-remodal-id=bubbleModal]','standardModal',0)"},{action:"function_call",function:"stopBubbleLoadingScreen()"}]
        respond_to do |format|
          format.json {
            render json: {status:true, message:nil,actions:actions,data:data}
          } 
        end        
    end


end
