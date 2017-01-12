class PasswordResetsController < ApplicationController
  skip_before_filter :require_login

  # request password reset.
  # you get here when the user entered his email in the reset password form and submitted it.
  def create 
    @user = User.find_by_email(params[:email])

    # This line sends an email to the user with instructions on how to reset their password (a url with a random token)
    if @user
      if @user.crypted_password.blank? && @user.authorizations.where(login:true).length > 0
          flash[:display] = "login"
          redirect_to(login_path, notice: "Looks like you used #{@user.authorizations.where(login:true).take.provider.capitalize} to sign up. Please login with #{@user.authorizations.where(login:true).take.provider.capitalize}")
      else
        @user.deliver_reset_password_instructions!
        flash[:success] = "We sent the password reset email to #{params[:email]}. Check your email and follow the instructions to reset your login"
        flash[:display] = "login"
        redirect_to(login_path)
      end
    else
      flash[:display] = "login"
      redirect_to(login_path, alert: "Oops. We can't seem to find any user with the email #{params[:email]}. Is it entered correctly?")
    end
  end

  # This is the reset password form.
  def edit
    @token = params[:id]
    @user = User.load_from_reset_password_token(params[:id])

    if @user.blank?
      not_authenticated
      return
    end
  end

  # This action fires when the user has sent the reset password form.
  def update
    @token = params[:id]
    @user = User.load_from_reset_password_token(params[:id])

    if @user.blank?
      not_authenticated
      return
    end

    # the next line makes the password confirmation validation work
    @user.password_confirmation = params[:user][:password_confirmation]
    # the next line clears the temporary token and updates the password
    if @user.change_password!(params[:user][:password])
      auto_login(@user,true)
      redirect_to root_path
    else
      redirect_to(edit_password_reset_path, alert: "Hmm. Our system doesn't seem to accept your password. Try again! Make sure the two passwords matches each other")
    end
  end
end