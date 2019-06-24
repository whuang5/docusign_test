Rails.application.routes.draw do
  resources :agreements, only: [:index, :new, :create, :destroy]
  root 'welcome#index'
end
