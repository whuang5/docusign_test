Rails.application.routes.draw do
  get '/pdf_agreements/preview' => 'pdf_agreements#generate_signer_view'
  resources :agreements, only: [:index, :new, :create, :destroy]
  resources :template, only: [:create, :new]
  resources :pdf_agreements, only: [:create, :new, :show]
  post '/webhook' => "webhook#create"
  root 'welcome#index'
end
