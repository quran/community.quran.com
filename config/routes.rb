Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'community/splash'
  get 'arabic_transliterations/:id/render_surah', to: "arabic_transliterations#render_surah"
  root to: 'community#splash'
  post '/contact', to: 'contact_us#message'

  devise_for :users, controllers: {registrations: 'users/registrations'}
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  authenticated :admin_user do
    require 'sidekiq/web'
    require 'sidekiq-scheduler/web'

    mount Sidekiq::Web => '/sidekiq'
  end

  resources :arabic_transliterations, except: :delete
  resources :proof_read_comments
  resources :wbw_translations, except: :delete
  resources :wbw_texts, except: :delete
  resources :translation_proofreadings, except: :delete
  resources :surah_infos, except: :delete do
    member do
      get :history
      get :changes
    end
  end
end
