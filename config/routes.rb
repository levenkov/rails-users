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
  end

  namespace :admin do
    resources :users, only: %i[index edit update destroy] do
      member do
        patch :toggle_role
        delete :delete_avatar
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

  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'health#show'
end
