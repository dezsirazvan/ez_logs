Rails.application.routes.draw do
  devise_for :users
  namespace :api do
    resources :events, only: [ :index, :create ]
  end

  root "events#index"
  get "events", to: "events#index"
end
