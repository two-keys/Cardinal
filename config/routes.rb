# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check
  get 'contact_us' => 'contact_us#index'
  get 'admin_panel/index'

  get 'filters/simple', to: 'filters#simple'
  post 'filters/simple', to: 'filters#create_simple'
  resources :filters

  resources :tickets, only: %i[index show destroy]

  concern :auditable do
    member do
      get 'history'
      post 'history/:version_id/restore', action: 'restore', as: 'restore'
    end
  end

  get 'prompts/search', to: 'prompts#search'
  post 'prompts/search', to: 'prompts#generate_search'
  resources :prompts do
    match 'tags', action: 'update_tags', via: %i[put patch]
    post 'answer', to: 'prompts#answer'
    post 'revert', to: 'prompts#revert'
    match 'bump', action: 'bump', via: %i[put patch]
    collection do
      get 'lucky_dip'
    end
    concerns :auditable
  end

  resources :pseudonyms

  get 'characters/search', to: 'characters#search'
  post 'characters/search', to: 'characters#generate_search'
  resources :characters do
    match 'tags', action: 'update_tags', via: %i[put patch]
    concerns :auditable
  end

  resources :tags do
    post 'hide', to: 'tags#hide', on: :member
    collection do
      post :autocomplete
    end
  end

  resources :messages, only: %i[show create destroy update edit] do
    concerns :auditable
  end
  resources :chats, except: %i[show]
  post 'chats/mod_chat', to: 'chats#create_mod_chat', as: 'create_mod_chat'
  get 'chats/:id', to: 'chats#show'
  get 'chats/:id/search' => 'chats#search', as: 'chat_messages_search'
  get 'chats/:id/:page', to: 'chats#show'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  post 'resend_confirmation' => 'resend_confirmations#resend', as: 'resend_confirmation'

  post 'connect_code' => 'connect_code#create'
  patch 'connect_code' => 'connect_code#update'
  patch 'connect_code/consume' => 'connect_code#consume'

  post 'chats/:id/forceongoing' => 'chats#forceongoing'
  post 'chats/:id/resolve' => 'chats#resolve_mod_chat'
  delete 'chats/:id/:icon', to: 'chats#chat_kick', as: 'chat_kick'

  resources :reports, only: %i[new index show create]

  resources :announcements do
    concerns :auditable
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'announcements#index'

  get 'donation', to: 'donation#index'
  post 'create_stripe_session', to: 'donation#create_stripe_session'

  get '500', to: 'errors#internal_server_error'
  namespace :admin do
    resources :users, only: %i[index edit update destroy] do
      concerns :auditable
    end
    post 'users/:id/force_confirm' => 'users#force_confirm', as: 'force_confirm_user'
    resources :entitlements do
      concerns :auditable
    end
    resources :reports, only: %i[index show edit update destroy]
    resources :messages, only: %i[create]
    get 'messages/search' => 'messages#search', as: 'messages_search'
    resources :alerts
    resources :audit_logs, only: %i[index]
    resources :ads, only: %i[index]
    resources :mod_chats, only: %i[index]
    resources :ip_bans
    post 'ads/:id/approve' => 'ads#approve', as: 'approve_ad'
    delete 'ads/:id' => 'ads#destroy', as: 'ad'
    root 'admin_panel#index'
  end

  scope 'use' do
    get '(/:page)', to: 'use#show', defaults: { page: 'index' }, as: :use_page
  end

  scope 'schema' do
    get 'types', to: 'schema#types'
  end

  resources :themes
  post 'themess/:id/apply', to: 'themes#apply', as: 'apply_theme'
  post 'themess/:id/unapply', to: 'themes#unapply', as: 'unapply_theme'

  resources :ads
  get 'ads/:id/click', to: 'ads#click', ad: 'click_ad'

  get 'serviceworker' => 'pwa#service_worker', :as => :pwa_serviceworker, :constraints => { format: 'js' }
  get 'manifest' => 'pwa#manifest', as: :pwa_manifest, :constraints => { format: 'json' }
  get 'notifications' => 'chats#notifications', as: :notifications, :constraints => { format: 'json' }
  resources :push_subscriptions, only: %i[create destroy]
end
# rubocop:enable Metrics/BlockLength
