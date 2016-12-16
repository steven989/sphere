class UsersController < ApplicationController
    before_action :require_login, except: [:new, :create]


    def new
        @user = User.new 
    end

    def create
        result = User.create_user(
          user_params[:email].downcase,
          user_params[:first_name],
          user_params[:last_name],
          user_params[:user_type],
          user_params[:password],
          user_params[:password_confirmation]
          )
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
          @raw_bubbles_data = current_user.get_raw_bubbles_data(nil,true)
          @bubbles_parameters = current_user.get_bubbles_display_system_settings(true)
          @notifications = current_user.get_notifications(true)
          @all_tags = current_user.tags.order(tag: :asc).map {|tag| tag.tag}.uniq.to_json
          if @setting_for_activity_entry_details = SystemSetting.search("activity_detail_level_to_be_shown")
            @activity_definitions = ActivityDefinition.level(@setting_for_activity_entry_details.value_in_specified_type) #specify the specificity level of the activities shown 
          end
          # ----- this section contains all the variables needed to display Level, Challenge and Badge
            # --- badges
            @badges = current_user.user_badges.includes(:badge).includes(:notifications).order(id: :asc)
            # --- challenges
            # @challenges = current_user.current_challenges.includes(:notifications).order(id: :asc)
            @challenges = current_user.user_challenges.includes(:notifications).includes(:challenge).order(id: :asc)
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
      photo_uploaded = !((params[:photoUploaderInCreate] == "undefined") || (params[:photoUploaderInCreate] == "null") || params[:photoUploaderInCreate].blank?)
      tags_inputted = !((params[:tags] == "undefined") || (params[:tags] == "null") || params[:tags].blank?)

        if params[:name].blank?
              status = false
              message = "Please fill in required fields"
              actions=[{action:"add_class",class:"errorFormInput",element:".modalView#mainImportView input[name=name]"}]
        else
          name = params[:name]
          email = params[:email]
          photo = photo_uploaded ? params[:photoUploaderInCreate] : nil
          tags = tags_inputted ? JSON.parse(params[:tags]) : nil
          notes = params[:notes]
          result = Connection.insert_contact(current_user,name,email,nil,nil,nil,photo,tags,notes)
          if result[:status]
              raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
              notifications = current_user.get_notifications(false)
              bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
              connection = result[:data]
              status = true
              message = "#{connection.first_name} added to your Sphere!"
              actions=[{action:"function_call",function:"resetModal($('[data-remodal-id=importModal]'),3)"},{action:"function_call",function:"createTagginInCreate()"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles)"}]
              data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
          else
              status = false
              message = "Uh oh. Our robots couldn't add #{connection.first_name} for some reason. #{connection.errors.full_messages.join(', ')}"
              actions = nil
              data = nil
          end
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end
    end

    def new_activity
        @connection = Connection.find(params[:connection_id])
        @activity = Activity.new
    end

    def create_activity
      if params[:activity_definition_id]
        result = Activity.create_activity(current_user,params[:connection_id],params[:activity_definition_id],Date.today,0)
        if result[:status]
          raw_bubbles_data = current_user.get_raw_bubbles_data(nil,false)
          notifications = current_user.get_notifications(false)
          bubbles_parameters = current_user.get_bubbles_display_system_settings(false)
          status = true
          message = "Awesome. XP + #{result[:data][:quality_score_gained].round}!"
          actions = [{action:"function_call",function:"closeModalInstance(2000)"},{action:"function_call",function:"paintBubbles(returnedData.raw_bubbles_data,returnedData.notifications,returnedData.bubbles_parameters,prettifyBubbles)"}]
          data = {raw_bubbles_data:raw_bubbles_data,bubbles_parameters:bubbles_parameters,notifications:notifications}
        else
          status = false
          message = "Oops. Our robots ran into some problems. Let us know the error: #{result[:message]}"
          actions = nil
          data = nil
        end
      else
        status = false
        message = "Oops. Something is off. Please refresh and try again"
        actions = nil
        data = nil
      end
      respond_to do |format|
        format.json {
          render json: {status:status,message:message,actions:actions,data:data}
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
