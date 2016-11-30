class AuthorizationsController < ApplicationController

    # OAuth2 callback routes
    def google_login

        begin
            # Grab the email address
            email = request.env['omniauth.auth']['extra']['raw_info']['email']
            first_name = request.env['omniauth.auth']['extra']['raw_info']['given_name']
            last_name = request.env['omniauth.auth']['extra']['raw_info']['family_name']

        rescue => error
                @action = "open"
                @errors = "Authorization could not be completed. Please close this window and try again"
        else
            if email
                # If email address matches an existing user, log that user in
                existing_user = User.find_email(email)
                if existing_user
                    auto_login(existing_user)
                    @action = "close"
                else
                    # add photo in here later
                    result = User.create_user(email,first_name,last_name,"user",nil,nil,true)
                    if result[:status]
                        auto_login(result[:user])
                        authorization = current_user.authorizations.create(provider:"google",scope:"['email','profile']",data:"{email:'#{request.env['omniauth.auth']['extra']['raw_info']['email']}',name:'#{request.env['omniauth.auth']['extra']['raw_info']['name']}'}",login:true)
                        @action = "close"
                    else
                        @errors = "We could not create your user account for the following reasons: result[:message]. Please close this window and try again"
                        @action = "open"
                    end
                end
            else
                @action = "open"
                @errors = "Authorization could not be completed. Please close this window and try again"
            end
        end
        
    end

    def google_calendar
        authorization = current_user.authorizations.where(provider:'google').take
        if authorization
            updated_authorization_scope = (eval(authorization.scope.blank? ? "[]" : authorization.scope)+["email", "profile", "calendar"]).uniq.to_s
            authorization.assign_attributes(
                scope:updated_authorization_scope,
                data:"{email:'#{request.env['omniauth.auth']['extra']['raw_info']['email']}',name:'#{request.env['omniauth.auth']['extra']['raw_info']['name']}',access_token:'#{request.env['omniauth.auth']['credentials']['token']}',refresh_token:'#{request.env['omniauth.auth']['credentials']['refresh_token']}'}"
            )
        else
            authorization = current_user.authorizations.new(provider:"google",scope:"['email','profile','calendar']",data:"{email:'#{request.env['omniauth.auth']['extra']['raw_info']['email']}',name:'#{request.env['omniauth.auth']['extra']['raw_info']['name']}',access_token:'#{request.env['omniauth.auth']['credentials']['token']}',refresh_token:'#{request.env['omniauth.auth']['credentials']['refresh_token']}'}")
        end
        
        if authorization.save

        else
            authorization.error
        end
    end

    def google_contacts
        authorization = current_user.authorizations.where(provider:'google').take
        if authorization
            updated_authorization_scope = (eval(authorization.scope.blank? ? "[]" : authorization.scope)+["email", "profile", "contacts"]).uniq.to_s
            authorization.assign_attributes(
                scope:updated_authorization_scope,
                data:"{email:'#{request.env['omniauth.auth']['extra']['raw_info']['email']}',name:'#{request.env['omniauth.auth']['extra']['raw_info']['name']}',access_token:'#{request.env['omniauth.auth']['credentials']['token']}',refresh_token:'#{request.env['omniauth.auth']['credentials']['refresh_token']}'}"
            )
        else
            authorization = current_user.authorizations.new(provider:"google",scope:"['email','profile','contacts']",data:"{email:'#{request.env['omniauth.auth']['extra']['raw_info']['email']}',name:'#{request.env['omniauth.auth']['extra']['raw_info']['name']}',access_token:'#{request.env['omniauth.auth']['credentials']['token']}',refresh_token:'#{request.env['omniauth.auth']['credentials']['refresh_token']}'}")
        end
        
        if authorization.save

        else
            authorization.error
        end
    end

end
