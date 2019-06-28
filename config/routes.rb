Rails.application.routes.draw do
  resources :agreements, only: [:index, :new, :create, :destroy]
  resources :template, only: [:create, :new]
  post '/webhook' => "webhook#create"
  root 'welcome#index'
end
