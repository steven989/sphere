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

  def welcome_email(user)
    @user = user
    mail(:to => user.email,
         :subject => "Welcome to Sphere!") do |format|
        format.html
    end 
  end

  def expiring_connections_notification(number_of_expiring_connections,user,frequency)
    @user = user
    @number_of_expiring_connections = number_of_expiring_connections
    @frequency = frequency
    timezone = user.timezone ? TZInfo::Timezone.get(user.timezone) : TZInfo::Timezone.get("UTC")
    if @frequency == "today"
      @checkins = user.activities.where("created_at >= ?", timezone.local_to_utc(timezone.now.strftime("%Y-%m-%d").to_datetime-1)).length
      @plans =  user.plans.where("status ilike 'Planned' and created_at >= ?", timezone.local_to_utc(timezone.now.strftime("%Y-%m-%d").to_datetime-1)).length
    elsif @frequency == "this week"
      @checkins = user.activities.where("EXTRACT(WEEK FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now-1).strftime("%V").to_i,timezone.local_to_utc(timezone.now-1).year.to_i).length
      @plans =  user.plans.where("status ilike 'Planned' and EXTRACT(WEEK FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now-1).strftime("%V").to_i,timezone.local_to_utc(timezone.now-1).year.to_i).length
    else
      @checkins = user.activities.where("EXTRACT(MONTH FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now-1).month.to_i,timezone.local_to_utc(timezone.now-1).year.to_i).length
      @plans =  user.plans.where("status ilike 'Planned' and EXTRACT(MONTH FROM created_at) = ? and EXTRACT(YEAR FROM created_at) = ?", timezone.local_to_utc(timezone.now-1).month.to_i,timezone.local_to_utc(timezone.now-1).year.to_i).length
    end

    mail(:to => user.email,
         :subject => "Your Sphere activities #{@frequency}!") do |format|
        format.html
    end     
  end

  def events_and_reminders(user,events,reminders,timezone)
    @timezone = timezone
    @user = user
    @events = events
    @number_of_events = events.length
    @reminders = reminders
    @number_of_reminders = reminders.length

    if @number_of_events > 0 && @number_of_reminders == 0 
      subject = "You have #{@number_of_events} scheduled #{@number_of_events > 1 ? 'events' : 'event'} on Sphere today"
    elsif @number_of_events == 0 && @number_of_reminders > 0
      subject = "You have #{@number_of_reminders} #{@number_of_reminders > 1 ? 'reminders' : 'reminder'} on Sphere"
    elsif @number_of_events > 0 && @number_of_reminders > 0
      subject = "You have #{@number_of_reminders} #{@number_of_reminders > 1 ? 'reminders' : 'reminder'} and #{@number_of_events} scheduled #{@number_of_events > 1 ? 'events' : 'event'} on Sphere today"
    end

    mail(:to => user.email,
         :subject => subject) do |format|
        format.html
    end
  end

end
