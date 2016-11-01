Rails.application.routes.draw do
  
  root to: 'users#dashboard'
  post 'users/create_connection' => 'users#create_connection', as: 'create_connection'
  post 'users/create' => 'users#create', as: 'create_user'
  get 'users/new' => 'users#new', as: 'create_account'
  get 'login' => 'user_sessions#new', :as => :login
  get 'logout' => 'user_sessions#destroy', :as => :logout
  resources :user_sessions

end
