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
        @connections = current_user.connections
        @activities = current_user.activities
    end

    def new_connection
       @connection = Connection.new 
    end

    def create_connection
        connection = Connection.new(connection_params)
        if connection.save
            connection.update_attributes(user_id: current_user.id)
            redirect_to root_path, notice: "Successfully created"
        else
            redirect_to root_path, alert: "Could not be created"
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
          redirect_to root_path, notice: "Successfully created"
       else 
          render action: :new_activity
       end
    end

    private
    def connection_params
        params.require(:connection).permit(:first_name,:last_name)
    end

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
