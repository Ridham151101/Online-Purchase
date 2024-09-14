Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :purchases, only: [:new, :create]

  get '/zipcode_info', to: 'purchases#fetch_zipcode_info'
  get 'items_for_ew_flag', to: 'purchases#items_for_ew_flag'
  # Defines the root path route ("/")
  # root "articles#index"
end
