namespace :system do

    desc 'Run scheduled tasks on the hour'
    task :run_scheduled_events, [:force_all] => [:environment] do |t, args|
        force_all = args[:force_all].nil? ? false : (args[:force_all] == "true" ? true : false)
        ScheduledTask.run_all_tasks(force_all)
    end 

    desc 'Daily system level tasks'
    task :daily_system_level_tasks => [:environment] do |t, args|
        Notification.destroy_expired_notifications
    end

    desc 'Daily user and connection level tasks'
    task :daily_user_and_connection_level_tasks => [:environment] do |t, args|
        User.app_users.each do |user|
            # 1) Find badges
            user.find_badges
            # 2) Update nightly stats
            StatisticDefinition.triggers("individual","nightly",user)
            # 3) daily_connection_tasks
            user.daily_connection_tasks
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
