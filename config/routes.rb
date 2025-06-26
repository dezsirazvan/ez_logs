Rails.application.routes.draw do
  # Root route
  root "dashboard#index"

  # Authentication routes
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  # Main dashboard route
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Individual routes (not nested under dashboard)
  get "settings", to: "dashboard#settings", as: :settings
  get "profile", to: "dashboard#profile", as: :profile
  get "stories", to: "dashboard#stories", as: :stories
  get "stories/:id", to: "dashboard#story", as: :story

  # Events routes
  resources :events, only: [:index, :show]

  # Users routes (admin only)
  resources :users do
    member do
      patch :lock
      patch :unlock
      patch :activate
      patch :deactivate
    end
  end

  # User profile routes
  resource :profile, only: [:edit, :update], controller: 'users/profiles'

  # API Keys routes (admin only)
  namespace :companies do
    resources :api_keys
  end

  # API routes
  namespace :api do
    resources :events, only: [:create, :index, :show]
    namespace :v1 do
      resources :alerts, only: [:create, :index]
    end
  end
end
