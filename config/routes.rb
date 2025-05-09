Rails.application.routes.draw do
  namespace :api do
    resources :events, only: [ :index, :create ]
  end

  root "events#index"
  get "events", to: "events#index"
end
