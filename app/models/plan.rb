class Plan < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection
    scope :upcoming, -> { where("status ilike 'Planned' and date >= ?", Date.today)}
    scope :completed, -> { where("status ilike 'Planned' and date < ?", Date.today)}

    def self.create_event(user,event_parameters,connection=nil,connection_email_override=nil,access_token=nil,expires_at=nil,calendar_id="primary",put_on_google=true)
        date = event_parameters[:date]
        start_time_only = event_parameters[:start_time]
        end_time_only = event_parameters[:end_time]
        summary = event_parameters[:summary]
        location = event_parameters[:location]
        details = event_parameters[:details]
        notify = event_parameters[:notify]

        connection_email = !connection_email_override.blank? ? connection_email_override : connection.email

        if put_on_google
            # Authenticate with Google and retrieve primary calendar
            begin
                # Check to see if there's an existing valid access token we can use without making a server request
                if access_token.nil? || access_token.nil? || Time.now > (DateTime.parse(expires_at) - 1.minute)
                  token_object = user.authorizations.where(provider:'google').take.refresh_token!  
                else
                  token_object = {access_token:access_token,expires_at:expires_at}
                end
                service = Google::Apis::CalendarV3::CalendarService.new
                access_token = AccessToken.new(token_object[:access_token])
                service.authorization = access_token
                calendar = service.get_calendar(calendar_id)
            rescue => error
                status = false
                message = error.message
            else
                # Calculate start time
                timezone_used = user.timezone ? user.timezone : calendar.time_zone
                Time.zone = timezone_used
                Chronic.time_class = Time.zone
                start_time = Chronic.parse("#{date} #{start_time_only}")
                end_time = Chronic.parse("#{date} #{end_time_only}")

                if start_time.blank?
                    status = false
                    message = "We can't seem to understand your time input '#{start_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
                elsif end_time.blank?
                    status = false
                    message = "We can't seem to understand your time input '#{end_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
                else
                    # Create Google Calendar events

                    begin
                        if notify
                            event = Google::Apis::CalendarV3::Event.new({
                                summary: summary,
                                location:location,
                                description:details,
                                start: {date_time:start_time.strftime("%Y-%m-%dT%H:%M:%S%z")},
                                end: {date_time:end_time.strftime("%Y-%m-%dT%H:%M:%S%z")},
                                attendees: [{email: connection_email}],
                                reminders: {use_default:true}
                                })
                        else
                            event = Google::Apis::CalendarV3::Event.new({
                                summary: summary,
                                location:location,
                                description:details,
                                start: {date_time:start_time.strftime("%Y-%m-%dT%H:%M:%S%z")},
                                end: {date_time:end_time.strftime("%Y-%m-%dT%H:%M:%S%z")},
                                reminders: {use_default:true}
                                })
                        end
                        result = service.insert_event(calendar.id,event,send_notifications:notify)
                    rescue => error
                        status = false
                        message = error.message
                    else
                        plan = Plan.create(
                                user_id:user.id,
                                connection_id:connection.id,
                                date:start_time.to_date,
                                date_time:start_time,
                                end_date_time: end_time,
                                timezone:timezone_used,
                                name:summary,
                                location:location,
                                status:"Planned",
                                calendar_id:calendar.id,
                                calendar_event_id:result.id,
                                invite_sent:notify,
                                details:details,
                                put_on_calendar: true
                                )
                        StatisticDefinition.triggers("individual","create_plan",User.find(user.id))
                        status = true
                        message = "Hangout created! We put it on your calendar for you"
                    end
                end
            end
        else
            token_object = nil
            start_time = Chronic.parse("#{date} #{start_time_only}")
            end_time = Chronic.parse("#{date} #{end_time_only}")
            if start_time.blank?
                status = false
                message = "We can't seem to understand your time input '#{start_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
            elsif end_time.blank?
                status = false
                message = "We can't seem to understand your time input '#{end_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
            else
                plan = Plan.create(
                        user_id:user.id,
                        connection_id:connection.id,
                        date:start_time.to_date,
                        date_time:start_time,
                        end_date_time: end_time,
                        timezone:user.timezone,
                        name:summary,
                        location:location,
                        status:"Planned",
                        calendar_id:nil,
                        calendar_event_id:nil,
                        invite_sent:false,
                        details:details,
                        put_on_calendar:false
                        )
                StatisticDefinition.triggers("individual","create_plan",User.find(user.id))
                status = true
                message = "Hangout created!"
            end
        end
        {status:status,message:message,access_token:token_object,plan:plan}
    end

    def update_event(user,event_parameters,connection=nil,connection_email_override=nil,access_token=nil,expires_at=nil,put_on_google_new=true)
        new_date = event_parameters[:date]
        new_start_time_only = event_parameters[:start_time]
        new_end_time_only = event_parameters[:end_time]
        new_summary = event_parameters[:summary]
        new_location = event_parameters[:location]
        new_details = event_parameters[:details]
        notify = event_parameters[:notify]

        new_connection_email = !connection_email_override.blank? ? connection_email_override : connection.email

        if put_on_google_new && self.put_on_calendar
            # Authenticate with Google and retrieve primary calendar
            begin
                # Check to see if there's an existing valid access token we can use without making a server request
                if access_token.nil? || access_token.nil? || Time.now > (DateTime.parse(expires_at) - 1.minute)
                  token_object = user.authorizations.where(provider:'google').take.refresh_token!  
                else
                  token_object = {access_token:access_token,expires_at:expires_at}
                end
                service = Google::Apis::CalendarV3::CalendarService.new
                access_token = AccessToken.new(token_object[:access_token])
                service.authorization = access_token
                event = service.get_event(calendar_id,calendar_event_id)
            rescue => error
                status = false
                message = error.message
            else
                # Calculate start time
                Time.zone = timezone
                Chronic.time_class = Time.zone
                new_start_time = Chronic.parse("#{new_date} #{new_start_time_only}")
                new_end_time = Chronic.parse("#{new_date} #{new_end_time_only}")
                if new_start_time_only.blank?
                    status = false
                    message = "We can't seem to understand your time input '#{new_start_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
                elsif new_end_time_only.blank?
                    status = false
                    message = "We can't seem to understand your time input '#{new_end_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
                else
                    if new_start_time != date_time
                        event.start.date_time = new_start_time.strftime("%Y-%m-%dT%H:%M:%S%z")
                        self.date = new_start_time.to_date
                        self.date_time = new_start_time
                        update_notification = true
                    end
                    if new_end_time != end_date_time
                        event.end.date_time = new_end_time.strftime("%Y-%m-%dT%H:%M:%S%z")
                        self.end_date_time = new_end_time
                    end
                    if new_summary != name
                        event.summary = new_summary
                        self.name = new_summary
                    end

                    if new_location != location
                        event.location = new_location
                        self.location = new_location
                    end

                    if new_details != details
                        event.description = new_details
                        self.details = new_details
                    end
                    # Create Google Calendar events
                    begin
                        result = service.update_event(calendar_id,calendar_event_id,event,send_notifications:notify)
                    rescue => error
                        status = false
                        message = error.message
                    else
                        self.save
                        status = true
                        message = "Event successfully updated"
                        if update_notification 
                            user.notifications.where(notification_type:"upcoming_plan").each { |notification|
                                if notification.value_in_specified_type[:plan_id] == self.id
                                    notification.assign_attributes(expiry_date:self.date_time)
                                    notification.save
                                end
                            }
                        end
                    end
                end
            end
        elsif put_on_google_new && !self.put_on_calendar #delete local event and create a whole new event
            result = Plan.create_event(self.user,
                                        {   date:new_date,
                                            start_time:new_start_time_only,
                                            end_time:new_end_time_only,
                                            summary:new_summary,
                                            location:new_location,
                                            details:new_details,
                                            notify:notify
                                        },
                                       connection,
                                       connection_email_override,
                                       access_token,
                                       expires_at,
                                       "primary",
                                       put_on_google_new
                                        )
            status = result[:status]
            message= result[:message]
            access_token = result[:access_token]
            if status
                self.destroy
            end           
        else #update local event
                new_start_time = Chronic.parse("#{new_date} #{new_start_time_only}")
                new_end_time = Chronic.parse("#{new_date} #{new_end_time_only}")
                if new_start_time_only.blank?
                    status = false
                    message = "We can't seem to understand your time input '#{new_start_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
                elsif new_end_time_only.blank?
                    status = false
                    message = "We can't seem to understand your time input '#{new_end_time_only}'. Try something else? (e.g. 4:30pm, 15:00)"
                else
                    if new_start_time != date_time
                        self.date = new_start_time.to_date
                        self.date_time = new_start_time
                        update_notification = true
                    end
                    if new_end_time != end_date_time
                        self.end_date_time = new_end_time
                    end
                    if new_summary != name
                        self.name = new_summary
                    end

                    if new_location != location
                        self.location = new_location
                    end

                    if new_details != details
                        self.details = new_details
                    end

                    self.save
                    status = true
                    message = "Event successfully updated"
                    if update_notification 
                        user.notifications.where(notification_type:"upcoming_plan").each { |notification|
                            if notification.value_in_specified_type[:plan_id] == self.id
                                notification.assign_attributes(expiry_date:self.date_time)
                                notification.save
                            end
                        }
                    end
                end
                self.delete_event(false,nil,nil,false) if !put_on_google_new
        end
        
        {status:status,message:message,access_token:token_object}        
    end

    def delete_event(notify,access_token=nil,expires_at=nil,delete_local=true)
        # Check to see if there's an existing valid access token we can use without making a server request
        if access_token.nil? || access_token.nil? || Time.now > (DateTime.parse(expires_at) - 1.minute)
          token_object = user.authorizations.where(provider:'google').take.refresh_token!  
        else
          token_object = {access_token:access_token,expires_at:expires_at}
        end

        # Authenticate with Google and retrieve primary calendar
        
        begin
            if !self.calendar_event_id.blank?
                service = Google::Apis::CalendarV3::CalendarService.new
                access_token = AccessToken.new(token_object[:access_token])
                service.authorization = access_token
                service.delete_event(calendar_id,calendar_event_id,send_notifications:notify)
            end
        rescue => error
            status = false
            message = error.message
        else
            if delete_local
                self.update_attributes(status:"Cancelled")
                self.user.notifications.where(notification_type:"upcoming_plan").each { |notification|
                    if notification.value_in_specified_type[:plan_id] == self.id
                        notification.destroy
                    end
                }
            else
                self.update_attributes(calendar_id:nil,calendar_event_id:nil,put_on_calendar:false)
            end
            status = true
            message = "Event cancelled"
        end 
        {status:status,message:message,access_token:token_object}
    end

    def date_time_in_zone(which_time,part=nil)
        if which_time == "start_time"
            if part == "date"
                date_time ? date_time.in_time_zone(timezone).to_date : nil
            elsif part == "time"
                date_time ? date_time.in_time_zone(timezone).strftime("%l:%M%p") : nil
            else
                date_time ? date_time.in_time_zone(timezone) : nil
            end
        elsif which_time == "end_time"
            if part == "date"
                end_date_time ? end_date_time.in_time_zone(timezone).to_date : nil
            elsif part == "time"
                end_date_time ? end_date_time.in_time_zone(timezone).strftime("%l:%M%p") : nil
            else
                end_date_time ? end_date_time.in_time_zone(timezone) : nil
            end
        end
    end

    def self.first_upcoming(user,connection)
        plan = Plan.where("user_id = ? and connection_id = ? and date_time > ? and status not ilike 'Cancelled'",user.id,connection.id,Time.now).order(date_time: :asc)
        plan.length == 0 ? nil : plan.first
    end

    def self.last(user,connection)
        plan = Plan.where("user_id = ? and connection_id = ? and date_time < ? and status not ilike 'Cancelled'",user.id,connection.id,Time.now).order(date_time: :desc)
        plan.length == 0 ? nil : plan.first
    end

    def datetime_humanized
        Plan.to_human_datetime(date_time.in_time_zone(timezone))
    end

    def name_with_parentheses_removed
        part_to_remove = name.match(/\(.+\)/).to_s
        part_removed = name.gsub(part_to_remove,"")
        part_removed.strip
    end

    def self.to_human_datetime(datetime)
        date = datetime.to_date
        timezone_offset_int = datetime.strftime('%z').gsub("0","").to_i
        timezone_object = ActiveSupport::TimeZone[timezone_offset_int]
        current_date_in_timezone = Time.now.in_time_zone(timezone_object).to_date
        days_diff = (date - current_date_in_timezone).to_i
        if days_diff == 0
            date_humanized = "today"
        elsif days_diff == 1
            date_humanized = "tomorrow"
        elsif days_diff >= 7 && days_diff < 14
            date_humanized = "next #{date.strftime('%A')} (#{date.strftime("%B %e")})"
        elsif days_diff < 7
            if date.strftime("%u").to_i < current_date_in_timezone.strftime("%u").to_i
                date_humanized = "this coming #{date.strftime('%A')} (#{date.strftime("%B %e")})"
            else
                date_humanized = "this #{date.strftime('%A')} (#{date.strftime("%B %e")})"
            end
        else
            date_humanized = "#{date.strftime("%B %e")}"
        end

        hour_in_12 = datetime.strftime('%l')
        minute = datetime.strftime('%M')
        am_pm = datetime.strftime('%p')
        "#{date_humanized} at #{hour_in_12}:#{minute}#{am_pm}"
    end

    def last_activity_date_difference_humanized
        Plan.to_human_time_difference_past(days_to_last_plan_string)
    end

    def days_to_last_plan_string
        plan_date = date_time.to_date
        timezone_offset_int = date_time.strftime('%z').gsub("0","").to_i
        timezone_object = ActiveSupport::TimeZone[timezone_offset_int]
        current_date_in_timezone = Time.now.in_time_zone(timezone_object).to_date
        days_diff = (current_date_in_timezone - plan_date).to_i
        days_diff
    end

    def self.to_human_time_difference_past(days)
        if days == 0
            date_diff_humanized = "earlier today"
        elsif days == 1
            date_diff_humanized = "yesterday"
        elsif days > 1 && days < 8
            date_diff_humanized = "#{days} days ago"
        else
            if (days/7) == 1
                date_diff_humanized = "a week ago"
            elsif (days/7) > 1 && (days/7) < 4
                date_diff_humanized = "#{days/7} weeks ago"
            else
                if (days.to_f/30.4).round == 1
                    date_diff_humanized = "a month ago"
                elsif (days.to_f/30.4).round > 1 && (days.to_f/30.4).round < 12
                    date_diff_humanized = "#{(days.to_f/30.4).round} months ago"
                else
                    if (days.to_f/365).round == 1
                        date_diff_humanized = "a year ago"
                    else
                        date_diff_humanized = "#{(days.to_f/365).round} years ago"
                    end
                end
            end
        end
    end

end
