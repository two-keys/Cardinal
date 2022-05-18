# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  resources :filters
  scope 'prompts' do
    get 'search', to: 'prompts#search'
    post 'search', to: 'prompts#generate_search'
  end
  resources :prompts do
    match 'tags', action: 'update_tags', via: %i[put patch]
    match 'bump', action: 'bump', via: %i[put patch]
  end

  resources :tags
  resources :messages, only: %i[show create destroy update edit]
  resources :chats, except: :show
  get 'chats/:id', to: 'chats#show'
  get 'chats/:id/:page', to: 'chats#show'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  post 'connect_code' => 'connect_code#create'
  patch 'connect_code' => 'connect_code#update'

  post 'chats/:id/forceongoing' => 'chats#forceongoing'

  resources :announcements
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'announcements#index'

  get 'donation', to: 'donation#index'
  post 'create_stripe_session', to: 'donation#create_stripe_session'

  get '500', to: 'errors#internal_server_error'
  namespace :admin do
    resources :users, only: %i[index edit update destroy]
  end

  scope 'use' do
    get '(/:page)', to: 'use#show', defaults: { page: 'index' }, as: :use_page
  end

  scope 'schema' do
    get 'types', to: 'schema#types'
  end
end
# rubocop:enable Metrics/BlockLength
