Rails.application.routes.draw do
  root :to => 'admin/home#index'
  mount ShopifyApp::Engine, at: '/'

  namespace :admin do
    root 'home#index'
    resources :quotations
    get '/billing', to: 'billing#index', as: 'billing'
    get '/settings', to: 'settings#index', as: 'settings'
    get '/quotations_samples', to: 'quotations#samples', as: 'quotations_samples'

    ## Temporary routes
    resources :articles do
      resources :comments
    end

    get '/pricing', to: 'pricing#index'
    get 'welcome/index'
    ## Temporary routes end
  end

#### Routes for customer portal
  get Rails.configuration.custom_config['proxy_path'], to: redirect(Rails.configuration.custom_config['proxy_path']+'/dashboard')

  scope Rails.configuration.custom_config['proxy_path']  do
    resources :articles do
      resources :comments
    end

    get '/dashboard', to: 'dashboard#index', as: 'dashboard'

    resources :quotations
    #resources :customers

    get '/billing', to: 'billing#index', as: 'billing'
    get '/settings', to: 'settings#index', as: 'settings'
    get '/templates', to: 'templates#index', as: 'templates'
    get '/cart', to: 'cart#index', as: 'cart'
    get 'pricing/index'
    get 'pricing/need'
  end
#### Routes for customer portal end


  # Default route came with rails, have to check what to do with it.
  root 'welcome#index'
end