Rails.application.routes.draw do
  get '/robots.txt' => 'robots#robots'

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


  concern :photo_attachable do
    resources :photos, only: :index
  end

  concern :ownable do
    get 'owner/:owner' => 'gardens#index', on: :collection
  end

  resources :gardens do
    get 'timeline' => 'charts/gardens#timeline'
    get 'owner/:owner' => 'gardens#index', as: 'gardens_by_owner', on: :collection
  end

  resources :plantings, concerns: [:photo_attachable, :ownable] do
    get :harvests
    get :seeds
    collection do
      get 'owner/:owner' => 'plantings#index', as: 'plantings_by_owner'
      get 'crop/:crop' => 'plantings#index', as: 'plantings_by_crop'
    end
  end

  resources :seeds, concerns: [:photo_attachable, :ownable] do
    get :plantings
    collection do
      get 'owner/:owner' => 'seeds#index', as: 'seeds_by_owner'
      get 'crop/:crop' => 'seeds#index', as: 'seeds_by_crop'
    end
  end

  resources :harvests, concerns: [:photo_attachable, :ownable] do
    collection do
      get 'owner/:owner' => 'harvests#index', as: 'harvests_by_owner'
      get 'crop/:crop' => 'harvests#index', as: 'harvests_by_crop'
    end
  end

  resources :posts, concerns: :ownable do
    collection do
      get 'author/:author' => 'posts#index', as: 'posts_by_author'
    end
  end

  resources :scientific_names
  resources :alternate_names
  resources :plant_parts
  resources :photos

  delete 'photo_associations' => 'photo_associations#destroy'

  resources :crops, concerns: [:photo_attachable, :ownable] do
    get 'harvests' => 'harvests#index'
    get 'plantings' => 'plantings#index'

    # Charts
    get 'sunniness' => 'charts/crops#sunniness', constraints: { format: 'json' }
    get 'planted_from' => 'charts/crops#planted_from', constraints: { format: 'json' }
    get 'harvested_for' => 'charts/crops#harvested_for', constraints: { format: 'json' }

    collection do
      get 'requested' => 'crops#requested', as: 'requested_crops'
      get 'wrangle' => 'crops#wrangle', as: 'wrangle_crops'
      get 'hierarchy' => 'crops#hierarchy', as: 'crops_hierarchy'
      get 'search' => 'crops#search', as: 'search'
    end
  end

  resources :comments
  resources :roles
  resources :forums

  resources :follows, only: %i(create destroy)
  resources :likes, only: %i(create destroy)
  resources :members do
    get 'follows' => 'members#view_follows', as: 'member_follows'
    get 'followers' => 'members#view_followers', as: 'member_followers'
  end
  resources :notifications do
    get 'reply', on: :member
  end

  resources :places do
    collection do
      get 'search' => 'places#search', as: 'search_places'
      get ':place' => 'places#show', as: 'place'
    end
  end

  get 'auth/:provider/callback' => 'authentications#create'
  get 'members/auth/:provider/callback' => 'authentications#create'

  resources :admin, only: :index do
    get 'newsletter'
    resources :members
    get ':action' => 'admin#:action', on: :collection
  end

  namespace :api do
    namespace :v1 do
      jsonapi_resources :photos
      jsonapi_resources :crops
      jsonapi_resources :plantings
      jsonapi_resources :gardens
      jsonapi_resources :harvests
      jsonapi_resources :seeds
      jsonapi_resources :members
    end
  end

  get '/.well-known/acme-challenge/:id' => 'pages#letsencrypt'
  # CMS stuff  -- must remain LAST
  comfy_route :cms_admin, path: '/admin/cms'
  comfy_route :cms, path: '/', sitemap: false
end
