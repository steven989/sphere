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

  def invite_connections(added=false,user,connection)
    @user = user
    subject = added ? "#{user.first_name} has added you on Sphere!" : "#{user.first_name} has invited you to Sphere!"
    mail(:to => connection.email,
         :subject => subject) do |format|
        format.html
    end 
  end

  def expiring_connections_notification(number_of_expiring_connections,user)
    @user = user
    mail(:to => user.email,
         :subject => "You have #{number_of_expiring_connections} connections on Sphere who will soon expire!") do |format|
        format.html
    end     
  end

end
