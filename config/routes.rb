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

  # Dashboard routes
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "dashboard/profile", to: "dashboard#profile", as: :profile
  get "dashboard/settings", to: "dashboard#settings", as: :dashboard_settings
  get "dashboard/stories", to: "dashboard#stories", as: :dashboard_stories
  get "dashboard/stories/:id", to: "dashboard#story", as: :dashboard_story

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
    resources :api_keys, except: [:show]
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :events, only: [:create, :index]
      resources :alerts, only: [:create, :index]
    end
  end
end
