Rails.application.routes.draw do
  resources :agreements, only: [:index, :new, :create, :destroy]
  post '/webhook' => "webhook#create"
  root 'welcome#index'
end
