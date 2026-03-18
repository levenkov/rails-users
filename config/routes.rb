Rails.application.routes.draw do
  get 'health', to: 'health#show'

  devise_for :users,
    controllers: {
      registrations: 'users/registrations',
      sessions: 'users/sessions',
      passwords: 'users/passwords',
      omniauth_callbacks: 'users/omniauth_callbacks'
    }

  devise_scope :user do
    post '/users/auth/google_oauth2/mobile', to: 'users/omniauth_callbacks#google_mobile'
    post '/users/auth/google_oauth2/register_with_saved_token', to: 'users/omniauth_callbacks#register_with_saved_token'
    post '/users/deletion_request', to: 'users/registrations#deletion_request'
  end

  namespace :users do
    get :me, to: 'profiles#show'
  end

  namespace :api, defaults: { format: :json } do
    resource :profile, only: %i[show update]
    resources :users, only: [] do
      get :search, on: :collection
    end
    resources :markets do
      resources :articles
    end
    resources :orders, only: %i[index show create update] do
      resource :splitting, only: %i[show update] do
        resource :approval, only: %i[create destroy], module: :splitting
        resources :participants, only: %i[create destroy], module: :splitting
      end
    end
  end

  namespace :admin do
    resources :users, only: %i[index edit update destroy] do
      member do
        patch :toggle_role
        delete :delete_avatar
      end
    end
    resources :markets do
      resources :articles, except: :show
    end
    resources :orders, only: %i[index show] do
      member do
        patch :transition
      end
    end
    get '', to: redirect('/admin/users')
    resources :mail_setup, only: [ :index ] do
      collection do
        get :authorize_google
        get :callback
        post :send_test
      end
    end
  end

  namespace :office do
    resources :orders, only: %i[index show] do
      member do
        patch :transition
        patch :confirm_payment
      end
    end
    get '', to: redirect('/office/orders')
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :carts, only: %i[index show update destroy] do
    collection do
      post :add
      post :remove
    end
    member do
      post :add_participant
      delete :remove_participant
      post :toggle_ready
      post :copy
    end
  end

  resources :orders, only: %i[index show new create] do
    get :checkout, on: :collection
    member do
      post :archive
    end
    resource :splitting, only: :show
    resources :payment_transactions, only: %i[new create destroy]
  end

  resources :financial_transactions, only: %i[index new create edit update destroy]

  resources :markets, only: :show

  root 'markets#index'
end
