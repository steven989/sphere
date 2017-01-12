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

  def expiring_connections_notification(number_of_expiring_connections,user,frequency)
    @user = user
    @number_of_expiring_connections = number_of_expiring_connections
    @frequency = frequency
    timezone = user.timezone ? TZInfo::Timezone.get(user.timezone) : TZInfo::Timezone.get("UTC")
    if @frequency == "today"
      @checkins = user.activities.where("created_at >= ?", timezone.local_to_utc(timezone.now.strftime("%Y-%m-%d").to_datetime)).length
      @plans =  user.plans.where("status ilike 'Planned' and created_at >= ?", timezone.local_to_utc(timezone.now.strftime("%Y-%m-%d").to_datetime)).length
    elsif @frequency == "this week"
      @checkins = user.activities.where("EXTRACT(WEEK FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now).strftime("%V").to_i,timezone.local_to_utc(timezone.now).year.to_i).length
      @plans =  user.plans.where("status ilike 'Planned' and EXTRACT(WEEK FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now).strftime("%V").to_i,timezone.local_to_utc(timezone.now).year.to_i).length
    else
      @checkins = user.activities.where("EXTRACT(MONTH FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now).month.to_i,timezone.local_to_utc(timezone.now).year.to_i).length
      @plans =  user.plans.where("status ilike 'Planned' and EXTRACT(MONTH FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now).month.to_i,timezone.local_to_utc(timezone.now).year.to_i).length
    end

    mail(:to => user.email,
         :subject => "Your Sphere activity #{@frequency}!") do |format|
        format.text
    end     
  end

end
