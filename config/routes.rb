# frozen_string_literal: true

Rails.application.routes.draw do
  resources :chats
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  post 'theme' => 'theme_preference#update'
  resources :announcements
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'announcements#index'

  namespace :admin do
    resources :users, only: %i[index edit update destroy]
  end
end
