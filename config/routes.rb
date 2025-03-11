# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  get 'admin_panel/index'
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
  resources :chats, except: :show
  get 'chats/:id', to: 'chats#show'
  get 'chats/:id/:page', to: 'chats#show'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  post 'connect_code' => 'connect_code#create'
  patch 'connect_code' => 'connect_code#update'
  patch 'connect_code/consume' => 'connect_code#consume'

  post 'chats/:id/forceongoing' => 'chats#forceongoing'
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
    resources :reports, only: %i[index show edit update destroy]
    resources :messages, only: %i[create]
    resources :alerts
    resources :audit_logs, only: %i[index]
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

  get 'serviceworker' => 'pwa#service_worker', :as => :pwa_serviceworker, :constraints => { format: 'js' }
  get 'manifest' => 'pwa#manifest', as: :pwa_manifest, :constraints => { format: 'json' }
  resources :push_subscriptions, only: %i[create destroy]
end
# rubocop:enable Metrics/BlockLength
