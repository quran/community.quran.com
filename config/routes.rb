Rails.application.routes.draw do
  devise_for :users
  get 'community/splash'
  root to: 'community#splash'
   
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :arabic_transliterations
  resources :proof_read_comments
end
