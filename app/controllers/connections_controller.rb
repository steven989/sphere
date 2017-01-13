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
            AppUsage.log_action("Updated name for connection (#{first_name} #{last_name})",current_user)
            status = true
            message = "Name updated!"
            raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
            notifications = current_user.get_notifications(false)
            bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
            actions=[{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles,false)"}]
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
                AppUsage.log_action("Updated email for connection (#{connection.first_name}  #{connection.last_name})",current_user)
                status = true
                message = "Email updated!"
                # raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
                # notifications = current_user.get_notifications(false)
                # bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
                # actions=[{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles,false)"}]
                # data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
                actions = nil
                data = nil
            else
                status = false
                message = connection.errors.full_messages.join(', ')
                actions = nil
                data = nil
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

    def update_phone
        connection_id = params[:id]
        if !params[:value].blank?
            connection = Connection.find(connection_id)
            if connection.update_attributes(phone:params[:value])
                AppUsage.log_action("Updated phone for connection (#{connection.first_name}  #{connection.last_name})",current_user)
                status = true
                message = "Phone updated!"
                # raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
                # notifications = current_user.get_notifications(false)
                # bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
                # actions=[{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles,false)"}]
                # data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
                actions = nil
                data = nil
            else
                status = false
                message = connection.errors.full_messages.join(', ')
                actions = nil
                data = nil
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
        photo_uploaded = !((params[:photoUploader] == "undefined") || (params[:photoUploader] == "null") || params[:photoUploader].blank?)

        if params[:contact_frequency] == "other" && (params[:custom_frequency].blank? || params[:custom_frequency].to_i < 1 )
            status = false
            message = "Please enter a valid number of days"
            actions = [{action:"add_class",element:".modalView#editConnection input[name=other_days]",class:"errorFormInput"}]
        else
            if photo_uploaded
                connection.remove_photo!
                connection.save
                connection.photo = params[:photoUploader]
                usage_log_message = "Updated photo for connection (#{connection.first_name}  #{connection.last_name})"
                message = "#{connection.first_name}'s photo updated!"
            end
            
            if params[:contact_frequency] || params[:notes]
                target_contact_interval_in_days = (params[:contact_frequency] == "monthly" ? 30 : ( params[:contact_frequency] == "weekly" ? 7 : params[:custom_frequency].to_i ) )
                connection.assign_attributes(
                    id:params[:connection_id],
                    frequency_word:params[:contact_frequency],
                    target_contact_interval_in_days:target_contact_interval_in_days,
                    notes:params[:notes]
                )
                usage_log_message = "Updated connection (#{connection.first_name} #{connection.last_name})"
                message = "Awesome. We updated #{connection.first_name}'s info for you!"
            end
            if connection.save
                AppUsage.log_action(usage_log_message,current_user)
                Connection.port_photo_url_to_access_url(connection.id)
                status = true
                message = message
                actions = [{action:"function_call",function:"resetModal($('.modalView#editConnection  .modalContentContainer'),1)"},{action:"function_call",function:"closeModalInstance(100)"}]
                data = nil
                if photo_uploaded
                  raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
                  notifications = current_user.get_notifications(false)
                  bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
                  data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
                  actions.push({action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles,false)"})
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
            new_stats = current_user.stats
            level_num = new_stats[:level].to_i
            xp = new_stats[:xp]
            level_progress_lookup = Level.return_level_xps([level_num,level_num+1])
            points_gained_in_this_level = xp-level_progress_lookup[level_num]
            points_required_to_progress = level_progress_lookup[level_num+1]-level_progress_lookup[level_num]
            new_stats[:points_gained_in_this_level] = points_gained_in_this_level
            new_stats[:points_required_to_progress] = points_required_to_progress            
            data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications,new_stats:new_stats}
            actions = [{action:"fadeDelete",element:"#expiredConnectionRow#{params[:connection_id]}",fadeoutTime:600},{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles,false)"},{action:"function_call",function:"updateRealTimeStats(returnedData.new_stats)"},{action:"function_call",function:"updateUserLevelNotifications(returnedData.notifications.user_level)"}]
            if current_user.connections.expired.length == 0
                actions.push({action:"function_call",function:"putWordsBackInIfNoExpiredConnection(610)"}) 
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
                actions=[{action:"transitionViews",from:"[data-remodal-id=importModal] .modalView#mainImportView",to:"[data-remodal-id=importModal] .modalView#listSelect"},{action:"function_call",function:"populateImportSelectionList(returnedData)"},{action:"function_call",function:"checkIfAtImportLimit(null)"}]
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
        if params[:contactsToImport]
            contacts_imported = params[:contactsToImport].values
            if contacts_imported.length > 15
                max_connections = current_user.user_setting.get_value('max_number_of_connections')
                max_connections = max_connections ? max_connections.to_i : 50
                if current_user.stat('total_connections_added').blank? || current_user.stat('total_connections_added') < max_connections
                    Connection.delay.create_from_import(current_user,contacts_imported,nil,nil,merge_name)
                    status = true
                    message = "We're importing your contacts in the background since you're importing in a larger batch. Refresh your browser in a minute or so and they'll appear in your Sphere!"
                    actions=[{action:"function_call",function:"uncheckAllContactsImport()"},{action:"function_call",function:"remaining_connections=#{max_connections-current_user.stat('total_connections_added').to_i-contacts_imported.length};toggleAddToSphereButton()"},{action:"function_call",function:"closeModalInstance(100)"}]
                    data = nil
                else
                    status = false
                    message = "You've reached the limit of #{max_connections} connections!"
                    actions = nil
                    data = nil        
                end
            else
                result = Connection.create_from_import(current_user,contacts_imported,access_token,expires_at,merge_name)
                if result[:status] 
                  status = result[:status] 
                  raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
                  notifications = current_user.get_notifications(false)
                  new_stats = current_user.stats
                  bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
                  message = result[:message]
                  actions=[{action:"function_call",function:"uncheckAllContactsImport()"},{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles,false)"},{action:"function_call",function:"updateRealTimeStats(returnedData.new_stats);toggleAddToSphereButton()"},{action:"function_call",function:"updateUserLevelNotifications(returnedData.notifications.user_level)"},{action:"function_call",function:"closeModalInstance(100)"}]
                  data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications,new_stats:new_stats}
                else
                  status = result[:status]
                  message = result[:message]
                  actions = nil
                  data = result[:data]
                end
            end
        else
            status = false
            message = "Oops! You need to choose at least 1 contact to import"
            actions = nil
            data = nil
        end
        
        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
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

       StatisticDefinition.triggers("individual","destroy_connection",User.find(current_user.id))

       raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
       notifications = current_user.get_notifications(false)
       new_stats = current_user.stats
       bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
       message = "Connection permanently deleted"
       actions=[{action:"function_call",function:"updateBubblesData(returnedData.raw_bubbles_data)"},{action:"function_call",function:"updateRealTimeStats(returnedData.new_stats)"},{action:"function_call",function:"updateUserLevelNotifications(returnedData.notifications.user_level)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles,false)"},{action:"function_call",function:"closeModalInstance(100)"}]
       data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications,new_stats:new_stats}

       respond_to do |format|
          format.json {
            render json: {status:true, message:message,actions:actions,data:data}
          } 
       end
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
        timezone = current_user.timezone ? TZInfo::Timezone.get(current_user.timezone) : TZInfo::Timezone.get('America/New_York')
        date_of_last_activity_with_this_connection_utc = connection.activities.where("activity_definition_id is not null").last && connection.activities.where("activity_definition_id is not null").order(:date).last.created_at
        check_in_button_state =  date_of_last_activity_with_this_connection_utc.nil? || timezone.now.strftime("%Y-%m-%d").to_date > timezone.utc_to_local(date_of_last_activity_with_this_connection_utc).strftime("%Y-%m-%d").to_date
        data[:connection_id] = params[:connection_id]
        data[:photo] = connection.photo_url
        data[:name] = connection.name
        data[:email] = connection.email
        data[:phone] = connection.phone
        data[:notes] = connection.notes
        data[:contact_frequency] = connection.frequency_word
        data[:target_contact_interval_in_days] = connection.target_contact_interval_in_days

        last_plan = Plan.last(current_user,connection)
        last_checkin = current_user.activities.where(activity:"Check In",connection_id:connection.id).order(created_at: :desc).take

        if last_plan || last_checkin
            if last_checkin && !last_plan
                last_activity_time_string = Plan.to_human_time_difference_past((Date.today - last_checkin.created_at.to_date).to_i)
                last_activity_name_string = "Checked in"
            elsif !last_checkin && last_plan
                last_activity_time_string = last_plan.last_activity_date_difference_humanized
                last_activity_name_string = last_plan.name_with_parentheses_removed
            else
                days_to_last_plan = last_plan.days_to_last_plan_string
                days_to_last_checkin = (Date.today - last_checkin.created_at.to_date).to_i
                if days_to_last_plan < days_to_last_checkin
                    last_activity_time_string = Plan.to_human_time_difference_past(days_to_last_plan)
                    last_activity_name_string = last_plan.name_with_parentheses_removed
                else
                    last_activity_time_string = Plan.to_human_time_difference_past(days_to_last_checkin)
                    last_activity_name_string = "Checked in"
                end     
            end
            data[:lastPlanString] = "Last Hangout: #{last_activity_name_string} #{last_activity_time_string}"
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
            data[:planData] = {id:upcoming_plan.id,date:upcoming_plan.date_time_in_zone('start_time','date'),start_time:upcoming_plan.date_time_in_zone('start_time','time'),end_time:upcoming_plan.date_time_in_zone('end_time','time'),name:upcoming_plan.name_with_parentheses_removed,location:upcoming_plan.location,details:upcoming_plan.details,notify:upcoming_plan.invite_sent,put_on_google:upcoming_plan.put_on_calendar}
        else
            data[:upcomingPlanString] = "No current plans :("
            data[:hasUpcomingPlan] = false
        end
        actions= [{action:"function_call",function:"populateBubblesModal()"},{action:"function_call",function:"checkInButtons('#{check_in_button_state}',{})"},{action:"function_call",function:"initializeReModal('[data-remodal-id=bubbleModal]','standardModal',0)"},{action:"function_call",function:"stopBubbleLoadingScreen()"}]
        onboarding = current_user.user_setting.get_value('onboarding_progress')
        actions.push({action:"function_call",function:"setTimeout(function(){showOnboarding('#plans','6,7,8');},1200);"}) if (onboarding && (!onboarding[6] || !onboarding[7] || !onboarding[8]))

        if params[:searchClick] == true || params[:searchClick] == "true"
            AppUsage.log_action("Opened connection through search",current_user)
        end
        respond_to do |format|
          format.json {
            render json: {status:true, message:nil,actions:actions,data:data}
          } 
        end        
    end


end
