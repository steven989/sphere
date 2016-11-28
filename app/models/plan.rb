class Plan < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection

    def self.create_event(user,event_parameters,connection=nil,connection_email_override=nil,access_token=nil,expires_at=nil,calendar_id="primary")
        date = event_parameters[:date]
        time = event_parameters[:time]
        duration = event_parameters[:duration].to_f
        summary = event_parameters[:summary]
        location = event_parameters[:location]
        details = event_parameters[:details]
        notify = event_parameters[:notify]

        connection_email = !connection_email_override.blank? ? connection_email_override : connection.email

        # Check to see if there's an existing valid access token we can use without making a server request
        if access_token.nil? || access_token.nil? || Time.now > (DateTime.parse(expires_at) - 1.minute)
          token_object = user.authorizations.where(provider:'google').take.refresh_token!  
        else
          token_object = {access_token:access_token,expires_at:expires_at}
        end

        # Authenticate with Google and retrieve primary calendar
        begin
            service = Google::Apis::CalendarV3::CalendarService.new
            access_token = AccessToken.new(token_object[:access_token])
            service.authorization = access_token
            calendar = service.get_calendar(calendar_id)
        rescue => error
            status = false
            message = error.message
        else
            # Calculate start time
            Time.zone = calendar.time_zone
            Chronic.time_class = Time.zone
            start_time = Chronic.parse("#{date} #{time}")

            if start_time.blank?
                status = false
                message = "Our robots can't seem to understand your time input '#{time}'. Try something else? (e.g. 4:30pm, 15:00)"
            else
                # Create Google Calendar events

                begin
                    if notify
                        event = Google::Apis::CalendarV3::Event.new({
                            summary: summary,
                            location:location,
                            description:details,
                            start: {date_time:start_time.strftime("%Y-%m-%dT%H:%M:%S%z")},
                            end: {date_time:(start_time+duration.hours).strftime("%Y-%m-%dT%H:%M:%S%z")},
                            attendees: [{email: connection_email}],
                            reminders: {use_default:true}
                            })
                        else
                        event = Google::Apis::CalendarV3::Event.new({
                            summary: summary,
                            location:location,
                            description:details,
                            start: {date_time:start_time.strftime("%Y-%m-%dT%H:%M:%S%z")},
                            end: {date_time:(start_time+duration.hours).strftime("%Y-%m-%dT%H:%M:%S%z")},
                            reminders: {use_default:true}
                            })
                        end
                    result = service.insert_event(calendar.id,event,send_notifications:notify)
                rescue => error
                    status = false
                    message = error.message
                else
                    Plan.create(
                        user_id:user.id,
                        connection_id:connection.id,
                        date:start_time.to_date,
                        time:start_time.to_time,
                        timezone:calendar.time_zone,
                        name:summary,
                        location:location,
                        status:"Planned",
                        calendar_id:calendar.id,
                        calendar_event_id:result.id,
                        invite_sent:notify
                        )
                    status = true
                    message = "Event successfully created"
                end
            end
        end
        {status:status,message:message,access_token:token_object}
    end
end
