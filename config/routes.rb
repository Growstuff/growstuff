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

  concern :has_photos do
    resources :photos, only: :index
  end

  concern :has_owner do
    get 'owner/:owner' => 'gardens#index', as: :by_owner, on: :collection
  end

  resources :gardens, concerns: [:has_photos, :has_owner] do
    get 'timeline' => 'charts/gardens#timeline', constraints: { format: 'json' }
  end

  resources :plantings, concerns: [:has_photos, :has_owner] do
    resources :harvests
    resources :seeds
    collection do
      get 'crop/:crop' => 'plantings#index', as: 'plantings_by_crop'
    end
  end

  resources :seeds, concerns: [:has_photos, :has_owner] do
    resources :plantings
    get 'crop/:crop' => 'seeds#index', as: 'seeds_by_crop', on: :collection
  end

  resources :harvests, concerns: [:has_photos, :has_owner] do
    get 'crop/:crop' => 'harvests#index', as: 'harvests_by_crop', on: :collection
  end

  resources :posts do
    get 'author/:author' => 'posts#index', as: 'by_author', on: :collection
  end

  resources :scientific_names
  resources :alternate_names
  resources :plant_parts
  resources :photos

  delete 'photo_associations' => 'photo_associations#destroy'

  resources :crops, concerns: [:has_photos, :has_owner] do
    get 'gardens' => 'gardens#index'
    get 'harvests' => 'harvests#index'
    get 'plantings' => 'plantings#index'
    get 'seeds' => 'seeds#index'

    get 'places' => 'places#index'
    get 'members' => 'members#index'

    # Charts json
    get 'sunniness' => 'charts/crops#sunniness', constraints: { format: 'json' }
    get 'planted_from' => 'charts/crops#planted_from', constraints: { format: 'json' }
    get 'harvested_for' => 'charts/crops#harvested_for', constraints: { format: 'json' }

    collection do
      get 'requested'
      get 'wrangle'
      get 'hierarchy'
      get 'search'
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
    get 'search', on: :collection
  end

  get 'auth/:provider/callback' => 'authentications#create'
  get 'members/auth/:provider/callback' => 'authentications#create'

  resources :admin, only: :index do
    resources :members
    collection do
      get 'newsletter'
      get ':action' => 'admin#:action'
    end
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
