class UserSessionsController < ApplicationController
  def new
    @invite_required = SystemSetting.search('invite_code_required').value_in_specified_type
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
      if user && user.remember_me_token && (user.remember_me_token_expires_at > Time.now.utc)
        @user = login(params[:email], params[:password],false)
        set_remember_me_cookie!(@user) if @user
      else
        @user = login(params[:email], params[:password],true)
      end

      if @user
        AppUsage.log_action("Logged in",@user)
        redirect_back_or_to root_path
      else
        if user 
          flash[:email_login] = params[:email]
          redirect_to(login_path, alert: "Password doesn't match what we have on file!")
          flash[:display] = "login"
        else
          flash[:display] = "login"
          flash[:email_signup] = params[:email]
          redirect_to(login_path, alert: "Looks like you're a new user. Click Sign Up to create a profile!")
        end
      end
    end

  end

  def destroy
    AppUsage.log_action("Logged out",current_user)
    logout
    redirect_to login_path
  end
end