Rails.application.routes.draw do
  resources :user_events, only: [:new, :create]
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :activities, only: [:index]

  resources :user_events, only: [:new, :create, :edit, :update, :destroy]

  get '/redirect', to: 'calendars#redirect', as: 'redirect'
  get '/callback', to: 'calendars#callback', as: 'callback'
  get '/calendars', to: 'calendars#calendars', as: 'calendars'

  get '/dashboard', to: 'user_events#dashboard', as: 'dashboard'

end
