class AdminsController < ApplicationController
    before_action :require_login
    before_action :check_if_admin

    def dashboard
        @users = User.app_users.order(id: :asc)
        # View, create, edit levels
        
        # View, create, edit challenges
        # View, create, edit badges
    end

    def render_model_input_form
        model_name = params[:modelName]
        @available_user_statistics = StatisticDefinition.where(timeframe:"cumulative").order(name: :asc).map {|statdef| statdef.name}.join(', ')
        if model_name == "level"
            @levels = Level.all.order(level: :asc)
        elsif model_name == "badge"
            @badges = Badge.all.order(created_at: :desc)
            if @badges.length == 0
                @badges = [Badge.new]
            end
        elsif model_name == "challenge"
            @challenges = Challenge.all.order(created_at: :desc)
        elsif model_name == "activity_definition"
            @activity_definitions = ActivityDefinition.all.order(specificity_level: :asc, created_at: :desc)
        elsif model_name == "system_setting"
            @system_settings = SystemSetting.all.order(created_at: :asc)
        elsif model_name == "sign_up_code"
            @sign_up_codes = SignUpCode.where(user_id:nil).order(created_at: :desc)
        end

        respond_to do |format|
          format.html {
            render partial: "#{model_name}_input"
          }      
        end
    end

    def impersonate
        user = User.find(params[:id])
        impersonate_user(user)
        redirect_to root_path
    end

    def upload_graphics
        model = params[:model]
        id = params[:id]
        graphic_uploaded = !((params[:graphic] == "undefined") || (params[:graphic] == "null") || params[:graphic].blank?)

        if model == "level" || model == "badge" || model == "challenge"
            object = model == "level" ? Level.find(id) : ( model == "badge" ? Badge.find(id) : Challenge.find(id) )
            if object
                object.remove_graphic!
                object.save
                object.graphic = params[:graphic]
                if object.save
                    status = true
                    message = nil
                else
                    status = false
                    message = "Ran into some issues: #{object.errors.full_messages.join(', ')}"
                end
            else
                status = false
                message = "Couldn't find a #{model} record with ID #{id}"
            end
        else
            status = false
            message = "'#{model}' is not valid"
        end
        
    end

    def generate_sign_up_codes
        number_of_code = params[:number_of_code].to_i
        quantity = params[:quantity].to_i
        SignUpCode.create_sign_up_codes(nil,number_of_code,quantity)

        status = true
        message = "Codes successfully created"
        data = nil
        actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('sign_up_code')},2000)"}]

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end  

    end

    def update_sign_up_codes
        parsed_params = {}
        params.each do |key,value|
            if key.match /ID\$(\d+)\$ATTR\$(\w+)/ #The keys are all in the shape of ID$123$ATTR$some_attribute
                object_id = $1
                attribute = $2
                parsed_params[object_id] = {} unless parsed_params[object_id]
                parsed_params[object_id][attribute.to_sym] = value
            end
        end

        error_array = []

        parsed_params.values.each do |valueReceived| 

            delete = valueReceived[:delete] == "true" ? true : false
            id = valueReceived[:id].blank? ? nil : valueReceived[:id].to_i
            inputID = valueReceived[:inputId]

            code = valueReceived[:code]
            quantity = valueReceived[:quantity].to_i
            valid_after = valueReceived[:valid_after].to_date
            valid_before = valueReceived[:valid_before].to_date
            active = valueReceived[:active] == "true" ? true : false
            description = valueReceived[:description]

            result = SignUpCode.update_sign_up_code_non_user_codes(id,delete,code,quantity,valid_after,valid_before,active,description)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the signup codes. #{error_array.map{|error| error[:message]}.join(', ') }. Specific issues highlighted below"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements] ? error[:elements].map{|element| {action:"change_css",element:"#sign_up_code .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } : {action:"change_css",element:"#sign_up_code .update-instance[data-instance-id=#{error[:inputId]}]",css:{attribute:"border",value:"1px solid red"} } }.flatten
            actions.push({action:"function_call",function:"reCheck('sign_up_code',receivedDataFromAJAX.data.errorInputIds,'update')"})
            actions.reject! {|action| action.nil?}
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('sign_up_code')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end          
    end


    def update_system_settings
        parsed_params = {}
        params.each do |key,value|
            if key.match /ID\$(\d+)\$ATTR\$(\w+)/ #The keys are all in the shape of ID$123$ATTR$some_attribute
                object_id = $1
                attribute = $2
                parsed_params[object_id] = {} unless parsed_params[object_id]
                parsed_params[object_id][attribute.to_sym] = value
            end
        end

        error_array = []
        parsed_params.values.each do |valueReceived| 

            delete = valueReceived[:delete] == "true" ? true : false
            id = valueReceived[:id].blank? ? nil : valueReceived[:id].to_i
            inputID = valueReceived[:inputId]


            name = valueReceived[:name]
            data_type = valueReceived[:data_type]
            value = valueReceived[:value]
            description = valueReceived[:description]

            result = SystemSetting.update_system_setting(delete,id,name,data_type,value,description)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the system settings. #{error_array.map{|error| error[:message]}.join(', ') }. Specific issues highlighted below"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements] ? error[:elements].map{|element| {action:"change_css",element:"#system_setting .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } : {action:"change_css",element:"#system_setting .update-instance[data-instance-id=#{error[:inputId]}]",css:{attribute:"border",value:"1px solid red"} } }.flatten
            actions.push({action:"function_call",function:"reCheck('system_setting',receivedDataFromAJAX.data.errorInputIds,'update')"})
            actions.reject! {|action| action.nil?}
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('system_setting')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end          
    end

    def update_activity_definitions
        parsed_params = {}
        params.each do |key,value|
            if key.match /ID\$(\d+)\$ATTR\$(\w+)/ #The keys are all in the shape of ID$123$ATTR$some_attribute
                object_id = $1
                attribute = $2
                parsed_params[object_id] = {} unless parsed_params[object_id]
                parsed_params[object_id][attribute.to_sym] = value
            end
        end

        error_array = []
        parsed_params.values.each do |value| 

            delete = value[:delete] == "true" ? true : false
            id = value[:id].blank? ? nil : value[:id].to_i
            inputID = value[:inputId]


            activity = value[:activity]
            specificity_level = value[:specificity_level]
            point_shared_experience_one_to_one = value[:point_shared_experience_one_to_one]
            point_shared_experience_group_private = value[:point_shared_experience_group_private]
            point_shared_experience_group_public = value[:point_shared_experience_group_public]
            point_provide_help = value[:point_provide_help]
            point_receive_help = value[:point_receive_help]
            point_provide_gift = value[:point_provide_gift]
            point_receive_gift = value[:point_receive_gift]
            point_shared_outcome = value[:point_shared_outcome]
            point_shared_challenge = value[:point_shared_challenge]
            point_communication_digital = value[:point_communication_digital]
            point_communication_in_person = value[:point_communication_in_person]
            point_shared_interest = value[:point_shared_interest]
            point_intimacy = value[:point_intimacy]

            result = ActivityDefinition.update_activity_definition(delete,id,activity,specificity_level,point_shared_experience_one_to_one,point_shared_experience_group_private,point_shared_experience_group_public,point_provide_help,point_receive_help,point_provide_gift,point_receive_gift,point_shared_outcome,point_shared_challenge,point_communication_digital,point_communication_in_person,point_shared_interest,point_intimacy)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the activity definitions. #{error_array.map{|error| error.message}.join(', ') } See the highlighted cells"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements] ? error[:elements].map{|element| {action:"change_css",element:"#activity_definition .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } : {action:"change_css",element:"#activity_definition .update-instance[data-instance-id=#{error[:inputId]}]",css:{attribute:"border",value:"1px solid red"} } }.flatten
            actions.push({action:"function_call",function:"reCheck('activity_definition',receivedDataFromAJAX.data.errorInputIds,'update')"})
            actions.reject! {|action| action.nil?}
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('activity_definition')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end          
    end

    def update_levels
        parsed_params = {}
        params.each do |key,value|
            if key.match /ID\$(\d+)\$ATTR\$(\w+)/ #The keys are all in the shape of ID$123$ATTR$some_attribute
                object_id = $1
                attribute = $2
                parsed_params[object_id] = {} unless parsed_params[object_id]
                parsed_params[object_id][attribute.to_sym] = value
            end
        end

        error_array = []
        parsed_params.values.each do |value| 
            delete = value[:delete] == "true" ? true : false
            id = value[:id].blank? ? nil : value[:id].to_i
            inputID = value[:inputId]
            level = value[:level]
            criteria = value[:criteria]
            graphic = value[:graphic]
            result = Level.update_level(delete,id,level,criteria,graphic)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the levels."
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements] ? error[:elements].map{|element| {action:"change_css",element:"#level .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } : nil }.flatten
            actions.push({action:"function_call",function:"reCheck('level',receivedDataFromAJAX.data.errorInputIds,'update')"})
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('level')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end                
    end


    def update_challenges
        parsed_params = {}
        params.each do |key,value|
            if key.match /ID\$(\d+)\$ATTR\$(\w+)/ #The keys are all in the shape of ID$123$ATTR$some_attribute
                object_id = $1
                attribute = $2
                parsed_params[object_id] = {} unless parsed_params[object_id]
                parsed_params[object_id][attribute.to_sym] = value
            end
        end


        error_array = []
        parsed_params.values.each do |value| 
            delete = value[:delete] == "true" ? true : false
            id = value[:id].blank? ? nil : value[:id].to_i
            inputID = value[:inputId]
            name = value[:name]
            description = value[:description]
            instructions = value[:instructions]
            repeated_allowed = value[:repeated_allowed] == "true" ? true : false
            criteria = value[:criteria]
            reward = value[:reward]
            graphic = value[:graphic]

            result = Challenge.update_challenge(delete,id,name,description,instructions,repeated_allowed,criteria,reward,graphic)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the challenges: #{error_array.map {|error| error[:message]}.join(', ')}"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements] ? error[:elements].map{|element| {action:"change_css",element:"#challenge .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } : nil }.flatten.reject! {|element| element.nil? }
            actions.push({action:"function_call",function:"reCheck('challenge',receivedDataFromAJAX.data.errorInputIds,'update')"})
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('challenge')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end                

    end



    def update_badges
        parsed_params = {}
        params.each do |key,value|
            if key.match /ID\$(\d+)\$ATTR\$(\w+)/ #The keys are all in the shape of ID$123$ATTR$some_attribute
                object_id = $1
                attribute = $2
                parsed_params[object_id] = {} unless parsed_params[object_id]
                parsed_params[object_id][attribute.to_sym] = value
            end
        end

        error_array = []
        parsed_params.values.each do |value| 
            delete = value[:delete] == "true" ? true : false
            id = value[:id].blank? ? nil : value[:id].to_i
            inputID = value[:inputId]
            name = value[:name]
            description = value[:description]
            criteria = value[:criteria]
            graphic = value[:graphic]

            result = Badge.update_badge(delete,id,name,description,criteria,graphic)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the badges. See the highlighted cells"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements] ? error[:elements].map{|element| {action:"change_css",element:"#badge .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } : nil }.flatten
            actions.push({action:"function_call",function:"reCheck('badge',receivedDataFromAJAX.data.errorInputIds,'update')"})
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('badge')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end
    end


    def view_user_app_usage
        user = User.find(params[:id])
        user_app_usages = user.app_usages
        user_activities = user.activities
        user_plans = user.plans
        user_reminders = user.user_reminders
        timezone = TZInfo::Timezone.get('America/New_York')
        @combined_app_usages = []
        user_app_usages.each do |usage|
            @combined_app_usages.push({raw_timestamp:usage.created_at,timestamp:timezone.utc_to_local(usage.created_at).strftime("%Y-%m-%d %l:%M%p EST"),usage:usage.action,additional_info:usage.additional_info})
        end
        user_activities.each do |activity|
            @combined_app_usages.push({raw_timestamp:activity.created_at,timestamp:timezone.utc_to_local(activity.created_at).strftime("%Y-%m-%d %l:%M%p EST"),usage:activity.activity,additional_info:nil})
        end
        user_plans.each do |plan|
            @combined_app_usages.push({raw_timestamp:plan.created_at,timestamp:timezone.utc_to_local(plan.created_at).strftime("%Y-%m-%d %l:%M%p EST"),usage:"Scheduled an event",additional_info:"Put on calendar:#{plan.put_on_calendar} | Invite sent: #{plan.invite_sent}"})
        end
        user_reminders.each do |reminder|
            @combined_app_usages.push({raw_timestamp:reminder.created_at,timestamp:timezone.utc_to_local(reminder.created_at).strftime("%Y-%m-%d %l:%M%p EST"),usage:"Set a reminder",additional_info:"Has due date: #{!reminder.due_date.nil?}"})
        end

        @combined_app_usages.sort! {|a,b| b[:raw_timestamp] <=> a[:raw_timestamp]}
    end


    private

    def check_if_admin
        redirect_to login_path unless current_user.is? 'admin'
    end

end
