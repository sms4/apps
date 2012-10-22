ReduApps::Application.routes.draw do
  root :to => 'apps#index'

  resources :apps, :only => [:index, :show] do
    match '/checkout'  => 'checkout#update', :via => :post
    match '/checkout' => 'checkout#new', :via => :get
    member do
      get 'preview'
      post 'rate'
    end
    resources :comments, :except => :edit do
      resources :comments, :except => :edit
    end
  end

  resources :users, :only => [] do
    resources :favorites, :only => [:index, :create, :destroy]
  end

  ActionDispatch::Routing::Translator.translate_from_file('config/locales/routes.yml')
end
