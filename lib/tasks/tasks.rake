namespace :system do

    desc 'Run scheduled tasks on the hour'
    task :run_scheduled_events, [:force_all] => [:environment] do |t, args|
        force_all = args[:force_all].nil? ? false : (args[:force_all] == "true" ? true : false)
        ScheduledTask.run_all_tasks(force_all)
    end 

    desc 'Daily system level tasks'
    task :daily_system_level_tasks => [:environment] do |t, args|
        Notification.destroy_expired_notifications
        UserChallenge.expire_uncompleted_challenges
        UserReminder.remove_all_overdue_reminders(14)
        SentEmail.remove_all_useless_records
    end

    desc 'Daily user and connection level tasks'
    task :daily_user_and_connection_level_tasks => [:environment] do |t, args|
        User.app_users.each do |user|
            # 1) daily_connection_tasks (this has to be before the stats update as the connection scores in this part needs to be calculated first)
            user.daily_connection_tasks
            # 2) Update nightly stats
            StatisticDefinition.triggers("individual","nightly",User.find(user.id))
            # 3) Find badges
            user.find_badges
            # 4) Send out expiring notifications email
            ExternalNotification.send_external_notifications_for(user)
            # 5) Send out events email
            user.send_events_and_reminder_email
        end
    end 

    desc 'Weekly tasks'
    task :weekly_tasks => [:environment] do |t, args|
        # 1) Find challenges
        User.app_users.each do |user|
            user.find_challenges
        end        
    end 

end
