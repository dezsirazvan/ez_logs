Rails.application.routes.draw do
  # Devise authentication routes
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
    unlocks: "users/unlocks"
  }

  # MFA routes
  get "mfa/new", to: "users/mfa#new", as: :new_user_mfa
  post "mfa", to: "users/mfa#create", as: :user_mfa
  post "mfa/backup", to: "users/mfa#backup_code", as: :user_mfa_backup

  # Dashboard routes
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "dashboard/profile", to: "dashboard#profile", as: :profile
  get "dashboard/settings", to: "dashboard#settings", as: :settings
  get "dashboard/events", to: "dashboard#events", as: :events
  get "dashboard/team", to: "dashboard#team", as: :team

  # User profile management
  namespace :users do
    resource :profile, only: [:edit, :update]
    patch "profile/change_password", to: "profiles#change_password", as: :change_password
    patch "profile/enable_mfa", to: "profiles#enable_mfa", as: :enable_mfa
    patch "profile/disable_mfa", to: "profiles#disable_mfa", as: :disable_mfa
    patch "profile/regenerate_backup_codes", to: "profiles#regenerate_backup_codes", as: :regenerate_backup_codes
    
    resources :api_keys, except: [:show, :edit, :update] do
      member do
        patch :regenerate
      end
    end
  end

  # Team management
  namespace :teams do
    resources :members, only: [:index] do
      collection do
        post :invite
        delete :remove
        patch :update_role
        patch :transfer_ownership
        delete :cancel_invitation
      end
    end
    
    resource :settings, only: [:edit, :update] do
      collection do
        patch :update_settings
        patch :deactivate
        patch :activate
      end
    end
  end

  # Teams management
  resources :teams do
    member do
      get :members
      get :edit
      patch :update
      delete :destroy
      post :add_member
      delete :remove_member, to: 'teams#remove_member'
    end
  end

  # Users management
  resources :users do
    member do
      patch :deactivate
      patch :activate
    end
  end

  # Events management
  resources :events, only: [:index, :show, :destroy] do
    collection do
      get :search_suggestions
    end
  end

  # Admin routes
  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
    resources :users
    resources :teams
    resources :roles
    resources :audit_logs, only: [:index, :show]
    resources :api_keys, only: [:index, :show, :destroy]
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :events, only: [:index, :show, :create]
      resources :alerts, only: [:index, :show]
      resources :analytics, only: [:index]
    end
  end

  # Root route
  root "dashboard#index"

  # Health check
  get "health", to: "health#index"
end
