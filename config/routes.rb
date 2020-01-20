# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get '/robots.txt' => 'robots#robots'

  resources :garden_types
  resources :plant_parts

  devise_for :members, controllers: {
    registrations:      "registrations",
    passwords:          "passwords",
    sessions:           "sessions",
    omniauth_callbacks: "omniauth_callbacks"
  }
  devise_scope :member do
    get '/members/unsubscribe/:message' => 'members#unsubscribe', as: 'unsubscribe_member'
  end
  match '/members/:id/finish_signup' => 'members#finish_signup', via: %i(get patch), as: :finish_signup

  resources :authentications, only: %i(create destroy)

  get "home/index"
  root to: 'home#index'

  concern :has_photos do
    resources :photos, only: :index
  end

  resources :gardens, concerns: :has_photos, param: :slug do
    get 'timeline' => 'charts/gardens#timeline', constraints: { format: 'json' }
  end

  resources :plantings, concerns: :has_photos, param: :slug do
    resources :harvests
    resources :seeds
    collection do
      get 'crop/:crop' => 'plantings#index', as: 'plantings_by_crop'
    end
  end

  resources :seeds, concerns: :has_photos, param: :slug do
    get 'plantings' => 'plantings#index'
    get 'crop/:crop' => 'seeds#index', as: 'seeds_by_crop', on: :collection
  end

  resources :harvests, concerns: :has_photos, param: :slug do
    get 'crop/:crop' => 'harvests#index', as: 'harvests_by_crop', on: :collection
  end

  resources :posts do
    get 'author/:author' => 'posts#index', as: 'by_author', on: :collection
  end

  resources :scientific_names
  resources :alternate_names
  resources :plant_parts
  resources :photos

  resources :photo_associations, only: :destroy

  resources :crops, param: :slug, concerns: :has_photos do
    get 'harvests' => 'harvests#index'
    get 'plantings' => 'plantings#index'
    get 'seeds' => 'seeds#index'

    get 'places' => 'places#index'
    get 'members' => 'members#index'

    # Charts json
    get 'sunniness' => 'charts/crops#sunniness', constraints: { format: 'json' }
    get 'planted_from' => 'charts/crops#planted_from', constraints: { format: 'json' }
    get 'harvested_for' => 'charts/crops#harvested_for', constraints: { format: 'json' }
    post :openfarm

    collection do
      get 'requested'
      get 'wrangle'
      get 'hierarchy'
      get 'search'
    end
  end

  resources :comments
  resources :forums

  resources :follows, only: %i(create destroy)

  post 'likes' => 'likes#create'
  delete 'likes' => 'likes#destroy'

  resources :timeline

  resources :members, param: :slug do
    resources :gardens
    resources :seeds
    resources :plantings
    resources :harvests
    resources :posts

    resources :follows
    get 'followers' => 'follows#followers'
  end

  resources :messages
  resources :conversations do
    collection do
      delete 'destroy_multiple'
    end
  end

  resources :places, only: %i(index show), param: :place do
    get 'search', on: :collection
  end

  get 'auth/:provider/callback' => 'authentications#create'
  get 'members/auth/:provider/callback' => 'authentications#create'

  scope :admin do
    get '/' => 'admin#index', as: 'admin'
    get '/newsletter' => 'admin#newsletter', as: 'admin_newsletter'
    comfy_route :cms_admin, path: '/cms'
  end

  namespace :admin do
    resources :members, param: :slug
    resources :roles
  end

  namespace :api do
    namespace :v1 do
      jsonapi_resources :crops
      jsonapi_resources :gardens
      jsonapi_resources :harvests
      jsonapi_resources :members
      jsonapi_resources :photos
      jsonapi_resources :plantings
      jsonapi_resources :seeds
    end
  end

  get '/.well-known/acme-challenge/:id' => 'pages#letsencrypt'
  # CMS stuff  -- must remain LAST
  comfy_route :cms, path: '/', sitemap: false
end
