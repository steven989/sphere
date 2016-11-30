Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_OAUTH_CLIENT_ID"], ENV["GOOGLE_OAUTH_CLIENT_SECRET"], {
    name: "google_login",
    scope: "email, profile",
    include_granted_scopes: true,
    prompt:"select_account",
    callback_path: "/auth/google_oauth2/login/callback"
  }
  provider :google_oauth2, ENV["GOOGLE_OAUTH_CLIENT_ID"], ENV["GOOGLE_OAUTH_CLIENT_SECRET"], {
    name: "google_calendar",
    scope: "email, profile, calendar",
    include_granted_scopes: true,
    access_type:"offline",
    prompt:"consent select_account",
    callback_path: "/auth/google_oauth2/calendar/callback"
  }
  provider :google_oauth2, ENV["GOOGLE_OAUTH_CLIENT_ID"], ENV["GOOGLE_OAUTH_CLIENT_SECRET"], {
    name: "google_contacts",
    scope: "email, profile, contacts",
    include_granted_scopes: true,
    access_type:"offline",
    prompt:"consent select_account",
    callback_path: "/auth/google_oauth2/contacts/callback"
  }
end