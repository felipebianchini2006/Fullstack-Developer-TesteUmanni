Rails.application.routes.draw do
  devise_for :users

  # Root path
  root "home#index"

  # Profile routes
  resource :profile, only: [:show, :edit, :update, :destroy] do
    delete :remove_avatar, on: :collection
  end

  # Admin namespace
  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard

    resources :users do
      member do
        patch :toggle_role
        delete :remove_avatar
      end
      collection do
        get :import
        post :process_import
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
