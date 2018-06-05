Rails.application.routes.draw do
  get '/display_weada_calendar', to: 'calendars#display_weada_calendar', as: 'display_weada_calendar'
  get '/redirect', to: 'calendars#redirect', as: 'redirect'
  get '/callback', to: 'calendars#callback', as: 'callback'
  post '/redirect', to: 'calendars#callback'
  get '/dashboard', to: 'user_events#dashboard', as: 'dashboard'
  get '/generate_calendar', to: 'user_events#generate_calendar', as: 'generate_calendar'

  resources :user_events, only: [:new, :create]
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :activities, only: [:index]

  resources :user_events, only: [:new, :create, :edit, :update, :destroy]

end
