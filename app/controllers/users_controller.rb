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
        @connection = Connection.new
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
        
    end

    def create_activity
        
    end

    private
    def connection_params
        params.require(:connection).permit(:first_name,:last_name)
    end

    def user_params
        params.permit(:email, :password, :password_confirmation)
    end

    def require_login
        redirect_to login_path if !logged_in?
    end
end
