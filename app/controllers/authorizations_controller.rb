class AuthorizationsController < ApplicationController

    def google_login
        puts '---------------------------------------------------'
        puts "login"
        puts params.inspect
        puts request.env['omniauth.auth']
        puts request.env['omniauth.auth']['credentials']
        puts request.env['omniauth.auth']['credentials'].class
        puts request.env['omniauth.auth']['credentials']['fresh_token']
        puts '---------------------------------------------------'
        
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
        puts '---------------------------------------------------'
        puts params.inspect
        puts '---------------------------------------------------'        
    end

end
