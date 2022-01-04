# frozen_string_literal: true

Rails.application.routes.draw do
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

  get 'notifications' => 'notifications#index'
  resources :announcements
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'announcements#index'

  namespace :admin do
    resources :users, only: %i[index edit update destroy]
  end
end
