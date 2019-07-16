Rails.application.routes.draw do
  get '/pdf_agreements/preview' => 'pdf_agreements#generate_edit_view'
  #get '/pdf_agreements/preview' => 'pdf_agreements#redirect_preview_url'
  resources :agreements, only: [:index, :new, :create, :destroy]
  resources :template, only: [:create, :new]
  resources :pdf_agreements, only: [:create, :new, :show]
  post '/webhook' => "webhook#create"
  root 'welcome#index'
end
