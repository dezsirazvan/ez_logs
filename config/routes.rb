Rails.application.routes.draw do
  # Devise authentication routes
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations"
  }

  # MFA routes
  get "mfa/new", to: "users/mfa#new", as: :new_user_mfa
  post "mfa", to: "users/mfa#create", as: :user_mfa
  post "mfa/backup", to: "users/mfa#backup_code", as: :user_mfa_backup

  # Dashboard routes
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "dashboard/profile", to: "dashboard#profile", as: :profile
  get "dashboard/settings", to: "dashboard#settings", as: :settings
  get "dashboard/activity", to: "dashboard#activity", as: :activity
  get "dashboard/team", to: "dashboard#team", as: :team

  # Admin routes
  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
    resources :users
    resources :teams
    resources :roles
    resources :audit_logs, only: [ :index, :show ]
    resources :api_keys, only: [ :index, :show, :destroy ]
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :events, only: [ :index, :show, :create ]
      resources :alerts, only: [ :index, :show ]
      resources :analytics, only: [ :index ]
    end
  end

  # Root route
  root "dashboard#index"

  # Health check
  get "health", to: "health#index"
end
