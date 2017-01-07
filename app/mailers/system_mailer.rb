class SystemMailer < ApplicationMailer

  def scheduled_task_report(report)
    @report = report
    mail(
      to: ENV['ADMIN_EMAIL'], 
      subject: 'Scheduled task report'
      ) do |format|
        format.text
    end 
  end

  def reset_password_email(user)
      @user = User.find user.id
      @url  = edit_password_reset_url(@user.reset_password_token)
      mail(:to => user.email,
           :subject => "Your Sphere password has been reset")      
  end

end
