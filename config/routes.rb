Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'community/splash'
  root to: 'community#splash'
  
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  authenticated :admin_user do
    require 'sidekiq/web'
    require 'sidekiq-scheduler/web'
  
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :arabic_transliterations
  resources :proof_read_comments
end
