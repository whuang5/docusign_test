Rails.application.routes.draw do
  resources :agreements, only: [:index, :new, :create, :destroy]
  resources :template, only: [:create, :new]
  resources :pdf_agreements, only: [:create, :new, :show]
  post '/webhook' => "webhook#create"
  root 'welcome#index'
end
