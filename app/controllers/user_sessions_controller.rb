class UserSessionsController < ApplicationController
  def new

  end

  def create
    user = User.where(email:params[:email]).take
    if user
      login_authorizations = user.authorizations.where(login:true)
      if !login_authorizations.blank? && user.password.blank?
        oauth_alert = true
      else
        oauth_alert = false
      end
    else
      oauth_alert = false
    end

    if oauth_alert
      redirect_to(login_path, alert: "You signed up with #{login_authorizations.map {|login| login.provider.capitalize}.to_sentence}. Please use #{ login_authorizations.length == 1 ? login_authorizations.take.provider.capitalize : 'one of these services'} to log in")
    else
      if @user = login(params[:email], params[:password])
        redirect_back_or_to(:root, notice: 'Login successful')
      else
        if user 
          redirect_to(login_path, alert: "Incorrect password")
        else
          redirect_to(login_path, alert: "You do not have an account")
        end
      end
    end

  end

  def destroy
    logout
    redirect_to(login_path, notice: 'Logged out!')
  end
end