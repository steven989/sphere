class Authorization < ActiveRecord::Base
    belongs_to :user

    def data_value
        eval(data)
    end

    def data_value_for_key(key)
        data_value[key.to_sym]
    end

    def update_value_for_key(key,value)
        data_hash = data_value
        data_hash[key.to_sym] = value
        update_attributes(data:data_hash)
    end

    def refresh_token!
        response = HTTParty.post("https://accounts.google.com/o/oauth2/token",
            body: {
                grant_type: "refresh_token",
                client_id: ENV['GOOGLE_OAUTH_CLIENT_ID'],
                client_secret: ENV['GOOGLE_OAUTH_CLIENT_SECRET'],
                refresh_token: data_value_for_key(:refresh_token)
                })
        response = JSON.parse(response.body)

        {
            access_token: response["access_token"],
            expires_at: Time.now + response["expires_in"].to_i.seconds            
        }
    end        

end
