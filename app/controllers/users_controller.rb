class UsersController < ApplicationController
    before_action :require_login, except: [:new, :create]


    def new
        @user = User.new 
    end

    def create
        result = User.create_user(user_params[:email].downcase,user_params[:first_name],user_params[:last_name],user_params[:user_type],user_params[:password],user_params[:password_confirmation])
        if result[:status]
          auto_login(result[:user])
          redirect_to root_path
        else
          redirect_to(login_path, alert: "Could not create user. #{result[:message]}")
        end
    end

    def dashboard
        if current_user.is? "admin"
          redirect_to admin_dashboard_path
        else
          @settings = current_user.user_setting.value_evaled
          @connections = current_user.connections.active          
          @raw_bubbles_data = @connections.joins{ connection_score.outer }.pluck(:id,:score_quality,:score_time,:first_name,:last_name, :photo_access_url).map{ |result| {id:result[0],display:result[3]+' '+result[4],size:result[1],distance:result[2],photo_url:result[5] } }.to_json
          bubbles_parameters_object = SystemSetting.search("bubbles_parameters").value_in_specified_type
          @bubbles_parameters = {
            sizeOfGapBetweenBubbles:bubbles_parameters_object[:min_gap_between_bubbles],
            minDistance:bubbles_parameters_object[:min_distance_from_center_of_central_bubble],
            minBubbleSize:bubbles_parameters_object[:min_size_of_bubbles],
            maxBubbleSize:bubbles_parameters_object[:max_size_of_bubbles],
            numberOfRecursion:bubbles_parameters_object[:number_of_recursions],
            radiusOfCentralBubble:bubbles_parameters_object[:radius_of_central_bubble],
            centralBubbleDisplay:current_user.email,
            centralBubblePhotoURL:nil
            }.to_json

            if @setting_for_activity_entry_details = SystemSetting.search("activity_detail_level_to_be_shown")
              @activity_definitions = ActivityDefinition.level(@setting_for_activity_entry_details.value_in_specified_type) #specify the specificity level of the activities shown 
            end

          # ----- this section contains all the variables needed to display Level, Challenge and Badge
            # --- badges
            @badges = current_user.badges.order(id: :asc)
            # --- challenges
            @challenges = current_user.current_challenges.order(id: :asc)
            # --- level
            current_user_stats = current_user.stats
            @level_object = current_user.level
            @level_num = @level_object.level
            @xp = current_user_stats[:xp]
            level_progress_lookup = Level.return_level_xps([@level_num,@level_num+1])
            @level_progress_percent_string = (((@xp-level_progress_lookup[@level_num]).to_f/(level_progress_lookup[@level_num+1]-level_progress_lookup[@level_num]).to_f)*100.0).round.to_s+"%"
          # -----
        end
    end

    def new_connection
       @connection = Connection.new 
       @default_contact_interval = SystemSetting.search("default_contact_interval").value_in_specified_type
    end

    def create_connection
        if params[:name].blank? || params[:target_contact_interval_in_days].blank?
              status = false
              message = "Please fill in required fields"
              actions=[]
              actions.push({action:"change_css",element:".modalView#mainImportView input[name=name]",css:{attribute:"border",value:"1px solid red"}}) if params[:name].blank?
              actions.push({action:"change_css",element:".modalView#mainImportView input[name=target_contact_interval_in_days]",css:{attribute:"border",value:"1px solid red"}}) if params[:target_contact_interval_in_days].blank?
        else
          first_name = Connection.parse_first_name(params[:name])
          last_name = Connection.parse_last_name(params[:name])
          interval = params[:target_contact_interval_in_days].blank? ? current_user.user_setting.get_value(:default_contact_interval_in_days) : params[:target_contact_interval_in_days]
          connection = Connection.new(first_name:first_name,last_name:last_name,phone:params[:phone],email:params[:email],target_contact_interval_in_days:interval)
          if connection.save
              connection.update_attributes(user_id: current_user.id,active:true)
              current_user.activities.create(connection_id:connection.id,activity:"Added to Sphere",date:Date.today,initiator:0,activity_description:"Automatically created")
              connection.update_score
              status = true
              message = "Connection successfully added"
              actions=[]
          else
              status = false
              message = "Could not be created #{connection.errors.full_messages.join(', ')}"
              actions=[]
          end
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions}
          } 
        end
    end

    def new_activity
        @connection = Connection.find(params[:connection_id])
        @activity = Activity.new
    end

    def create_activity
      puts '---------------------------------------------------'
      puts params[:connection_id]
      puts '---------------------------------------------------'
      if params[:activity_definition_id]
        result = Activity.create_activity(current_user,params[:connection_id],params[:activity_definition_id],Date.today,0)
        if result[:status]
          status = true
          message = "Awesome. XP + #{result[:data][:quality_score_gained].round}!"
          actions = [{action:"function_call",function:"closeModalInstance(2000)"}]
        else
          status = false
          message = "Oops. Our robots ran into some problems. Let us know the error: #{result[:message]}"
          actions = nil
        end
      else
        status = false
        message = "Oops. Something is off. Please refresh and try again"
        actions = nil
      end
      respond_to do |format|
        format.json {
          render json: {status:status,message:message,actions:actions}
        } 
      end
    end

    def get_user_settings
      current_user_settings = current_user.user_setting
      current_user_settings = current_user_settings.blank? ? UserSetting.create_from_system_settings(current_user) : current_user_settings
      current_user_settings_evaled = current_user_settings.value_evaled
      formattedSettingsHash = {
                                send_event_booking_notification_by_default:{title:"Send calendar invites to my connections by default when creating a calendar event",value:current_user_settings_evaled[:send_event_booking_notification_by_default],type:"boolean"},
                                share_my_calendar_with_contacts:{title:"Enable connections to see my free/busy status when inviting me to an event",value:current_user_settings_evaled[:share_my_calendar_with_contacts],type:"boolean"},
                                default_contact_interval_in_days:{title:"Default number of days to connect with people",value:current_user_settings_evaled[:default_contact_interval_in_days],type:"number"},
                                event_add_granularity:{title:"Granularity of adding events",value:current_user_settings_evaled[:event_add_granularity],type:"selection",options:["Detailed","Quick"]}
                              }
        respond_to do |format|
          format.json {
            render json: {status:true,data:formattedSettingsHash,actions:[{action:"function_call",function:"populateSettingsForm()"}]}
          } 
        end
    end

    def update_user_settings
      send_event_booking_notification_by_default = params[:data][:send_event_booking_notification_by_default] == "true" ? true : false
      share_my_calendar_with_contacts = params[:data][:share_my_calendar_with_contacts] == "true" ? true : false
      default_contact_interval_in_days = params[:data][:default_contact_interval_in_days].to_i
      event_add_granularity = params[:data][:event_add_granularity]
      
      user_setting = current_user.user_setting
      if user_setting.update_value({send_event_booking_notification_by_default:send_event_booking_notification_by_default,share_my_calendar_with_contacts:share_my_calendar_with_contacts,default_contact_interval_in_days:default_contact_interval_in_days,event_add_granularity:event_add_granularity})
        status = true
        message = "Settings successfully updated"
        actions = [{action:"function_call",function:"closeModalInstance(2000)"}]
      else
        status = false
        message = "Settings could not be updated: user_setting.errors.full_messages.join(', ')"
        actions = nil
      end

      respond_to do |format|
        format.json {
          render json: {status:status,message:message,actions:actions}
        } 
      end
    end

    def update_tags
      connection = Connection.find(params[:connection_id])
      result = connection.update_tags(current_user,params[:tags])
      if result[:status]
        status = true
        message = "Tag updated!"
        actions = nil
        data = {connection_tags:result[:data],connection_id:params[:connection_id]}
      else
        status = false
        message = "Oops. Our robots encountered some issues while updating tags. Please let us know the error: #{result[:message]}"
        actions = nil
        data = {connection_tags:result[:data],connection_id:params[:connection_id]}
      end
      respond_to do |format|
        format.json {
          render json: {status:status,message:message,actions:actions,data:data}
        } 
      end
    end

    private

    def activity_params
       params.require(:activity).permit(:activity_definition_id,:date,:activity_description,:initiator) 
    end

    def user_params
        params.permit(:email, :password, :password_confirmation,:first_name,:last_name)
    end

    def require_login
        redirect_to login_path if !logged_in?
    end
end
