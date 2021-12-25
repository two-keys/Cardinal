Rails.application.routes.draw do
  post 'theme' => 'theme_preference#update'
  resources :announcements
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "announcements#index"
end
