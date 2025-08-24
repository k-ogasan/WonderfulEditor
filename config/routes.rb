Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'articles/index'
      get 'articles/show'
      get 'articles/create'
      get 'articles/update'
      get 'articles/destroy'
    end
  end
  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "User", at: "auth"
      resources :articles
    end
  end
end
