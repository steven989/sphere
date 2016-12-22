Rails.application.routes.draw do


  # General
  root to: 'users#dashboard'
  get 'login' => 'user_sessions#new', :as => :login
  get 'logout' => 'user_sessions#destroy', :as => :logout
  resources :user_sessions

  # Users controller

  get 'users/new_connection' => 'users#new_connection', as: 'new_connection'
  post 'users/create_connection' => 'users#create_connection', as: 'create_connection'
  get 'users/:connection_id/new_activity' => 'users#new_activity', as: 'new_activity'
  post 'users/create_activity' => 'users#create_activity', as: 'create_activity'
  post 'users/create' => 'users#create', as: 'create_user'
  get 'users/new' => 'users#new', as: 'create_account'
  get 'users/settings' => 'users#get_user_settings', as: 'get_user_settings'
  put 'users/settings' => 'users#update_user_settings', as: 'update_user_settings'
  put 'users/info' => 'users#update_user_info', as: 'update_user_info'
  get 'users/info' => 'users#get_user_info', as: 'get_user_info'
  put 'users/update_tags' => 'users#update_tags', as: 'update_tags'



  # Connections controller
  get 'connections/populate_connection_modal' => 'connections#populate_connection_modal', as: 'populate_connection_modal'
  post 'connections/:id/create_note' => 'connections#create_note', as: 'create_connection_note'
  put  'connections/update' => 'connections#update', as: 'update_connection'
  put  'connections/import' => 'connections#import', as: 'import_connection'
  post  'connections/create_from_import' => 'connections#create_from_import', as: 'create_from_import'
  put  'connections/destroy' => 'connections#destroy', as: 'destroy_connection'
  put  'connections/destroy' => 'connections#destroy_all', as: 'clear_connections'
  put 'connections/update_name' => 'connections#update_name', as: 'update_connection_name'
  put 'connections/update_email' => 'connections#update_email', as: 'update_connection_email'
  get 'connections/list_expired_connections' => 'connections#list_expired_connections', as: 'list_expired_connections'
  put 'connections/revive_expired_connections' => 'connections#revive_expired_connections', as: 'revive_expired_connections'

  # Admins controller
  get 'admins/dashboard' => 'admins#dashboard', as: 'admin_dashboard'
  get 'admins/render_model_input_form' => 'admins#render_model_input_form', as: 'render_model_input_form'
  put  'admins/update_levels' => 'admins#update_levels', as: 'update_levels'
  put  'admins/update_challenges' => 'admins#update_challenges', as: 'update_challenges'
  put  'admins/update_badges' => 'admins#update_badges', as: 'update_badges'
  put  'admins/update_activity_definitions' => 'admins#update_activity_definitions', as: 'update_activity_definitions'
  put  'admins/update_system_settings' => 'admins#update_system_settings', as: 'update_system_settings'
  put  'admins/upload_graphics' => 'admins#upload_graphics', as: 'upload_graphics'


  # Plans controller
  post 'plans' => 'plans#create', as: 'plans'
  put 'plans/cancel_plan' => 'plans#cancel', as: 'cancel_plan'
  put 'plans/modify_plan' => 'plans#update', as: 'modify_plan'

  # Authorization callback routes
  get 'auth/google_oauth2/login/callback' => 'authorizations#google_login', as: 'google_login_redirect'
  get 'auth/google_oauth2/calendar/callback' => 'authorizations#google_calendar', as: 'google_calendar_redirect'
  get 'auth/google_oauth2/contacts/callback' => 'authorizations#google_contacts', as: 'google_contacts_redirect'

  # Challenges controller
  put  'challenges/start' => 'challenges#start', as: 'start_challenge'
  put  'challenges/mark_complete' => 'challenges#mark_complete', as: 'complete_challenge'

end
