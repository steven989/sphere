Rails.application.routes.draw do

  root to: 'users#dashboard'
  get 'users/new_connection' => 'users#new_connection', as: 'new_connection'
  post 'users/create_connection' => 'users#create_connection', as: 'create_connection'
  get 'users/:connection_id/new_activity' => 'users#new_activity', as: 'new_activity'
  post 'users/:connection_id/create_activity' => 'users#create_activity', as: 'create_activity'
  post 'users/create' => 'users#create', as: 'create_user'
  get 'users/new' => 'users#new', as: 'create_account'

  post 'connections/:id/create_note' => 'connections#create_note', as: 'create_connection_note'

  get 'login' => 'user_sessions#new', :as => :login
  get 'logout' => 'user_sessions#destroy', :as => :logout
  resources :user_sessions

end
