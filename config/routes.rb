Rails.application.routes.draw do
  root to: "home#index"

  get "sign_up", to: "home#index"
  get "sign_in", to: "home#index"
  get "articles/new", to: "home#index"
  get "articles/:id", to: "home#index"
  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "User", at: "auth", controllers: {
        sessions: "api/v1/auth",
      }
      resources :articles do
        collection do
          get :drafts
        end
        member do
          get :draft
        end
      end
    end
  end
end
