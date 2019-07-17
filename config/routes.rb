Rails.application.routes.draw do
  get '/pdf_agreements/preview' => 'pdf_agreements#generate_edit_view'
  get '/pdf_agreements/console' => 'pdf_agreements#generate_console_view'
  get '/pdf_agreements/correct' => 'pdf_agreements#generate_correct_view'
  get "/pdf_agreements/new_preview" => 'pdf_agreements#redirect_preview_url'

  #get '/pdf_agreements/preview' => 'pdf_agreements#redirect_preview_url'
  resources :agreements, only: [:index, :new, :create, :destroy]
  resources :template, only: [:create, :new]
  resources :pdf_agreements, only: [:create, :new, :show]
  post '/webhook' => "webhook#create"
  root 'welcome#index'
end
