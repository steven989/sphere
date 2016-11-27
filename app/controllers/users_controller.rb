class UsersController < ApplicationController
    before_action :require_login, except: [:new, :create]


    def new
        @user = User.new 
    end

    def create
        @user = User.new(user_params)
        if @user.save
          auto_login(@user)
          redirect_to :root 
        else
          render action: :new
        end        
    end

    def dashboard
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
        @activities = current_user.activities
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
          connection = Connection.new(first_name:first_name,last_name:last_name,phone:params[:phone],email:params[:email],target_contact_interval_in_days:params[:target_contact_interval_in_days])
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
       @connection = Connection.find(params[:connection_id])
       activity = current_user.activities.new(activity_params)
       if activity.save
          activity.update_attributes(connection_id:params[:connection_id],activity:ActivityDefinition.find(activity.activity_definition_id).activity)
          @connection.update_score
          @connection.update_attributes(active:true)
          StatisticDefinition.triggers("individual","create_activity",current_user)
          redirect_to root_path, notice: "Successfully created"
       else 
          render action: :new_activity
       end
    end

    private

    def activity_params
       params.require(:activity).permit(:activity_definition_id,:date,:activity_description,:initiator) 
    end

    def user_params
        params.permit(:email, :password, :password_confirmation)
    end

    def require_login
        redirect_to login_path if !logged_in?
    end
end
