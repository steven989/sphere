Rails.application.routes.draw do

  root to: 'users#dashboard'
  get 'users/new_connection' => 'users#new_connection', as: 'new_connection'
  post 'users/create_connection' => 'users#create_connection', as: 'create_connection'
  get 'users/:connection_id/new_activity' => 'users#new_activity', as: 'new_activity'
  post 'users/:connection_id/create_activity' => 'users#create_activity', as: 'create_activity'
  post 'users/create' => 'users#create', as: 'create_user'
  get 'users/new' => 'users#new', as: 'create_account'

  post 'connections/:id/create_note' => 'connections#create_note', as: 'create_connection_note'
  put  'connections/update' => 'connections#update', as: 'update_connection'
  put  'connections/import' => 'connections#import', as: 'import_connection'
  post  'connections/create_from_import' => 'connections#create_from_import', as: 'create_from_import'

  get 'login' => 'user_sessions#new', :as => :login
  get 'logout' => 'user_sessions#destroy', :as => :logout
  resources :user_sessions


  # Admins controller
  get 'admins/dashboard' => 'admins#dashboard', as: 'admin_dashboard'
  get 'admins/render_model_input_form' => 'admins#render_model_input_form', as: 'render_model_input_form'
  put  'admins/update_levels' => 'admins#update_levels', as: 'update_levels'
  put  'admins/update_challenges' => 'admins#update_challenges', as: 'update_challenges'
  put  'admins/update_badges' => 'admins#update_badges', as: 'update_badges'

  resources :plans
  # Authorization callback routes
  get 'auth/google_oauth2/login/callback' => 'authorizations#google_login', as: 'google_login_redirect'
  get 'auth/google_oauth2/calendar/callback' => 'authorizations#google_calendar', as: 'google_calendar_redirect'
  get 'auth/google_oauth2/contacts/callback' => 'authorizations#google_contacts', as: 'google_contacts_redirect'

end
