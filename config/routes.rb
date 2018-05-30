Rails.application.routes.draw do
  resources :user_events, only: [:new, :create]
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :weather_conditions, except: [:index, :destroy, :new, :edit]
end
