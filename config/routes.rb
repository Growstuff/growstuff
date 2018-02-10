Growstuff::Application.routes.draw do
  get '/robots.txt' => 'robots#robots'

  resources :plant_parts

  devise_for :members, controllers: {
    registrations: "registrations",
    passwords: "passwords",
    sessions: "sessions",
    omniauth_callbacks: "omniauth_callbacks"
  }
  devise_scope :member do
    get '/members/unsubscribe/:message' => 'members#unsubscribe', as: 'unsubscribe_member'
  end
  match '/members/:id/finish_signup' => 'members#finish_signup', via: %i(get patch), as: :finish_signup

  resources :members

  resources :photos
  delete 'photo_associations' => 'photo_associations#destroy'

  resources :authentications, only: %i(create destroy)

  resources :plantings do
    resources :harvests
  end
  get '/plantings/owner/:owner' => 'plantings#index', as: 'plantings_by_owner'
  get '/plantings/crop/:crop' => 'plantings#index', as: 'plantings_by_crop'

  resources :gardens do
    get 'timeline' => 'charts/gardens#timeline'
  end
  get '/gardens/owner/:owner' => 'gardens#index', as: 'gardens_by_owner'

  resources :seeds
  get '/seeds/owner/:owner' => 'seeds#index', as: 'seeds_by_owner'
  get '/seeds/crop/:crop' => 'seeds#index', as: 'seeds_by_crop'

  resources :harvests
  get '/harvests/owner/:owner' => 'harvests#index', as: 'harvests_by_owner'
  get '/harvests/crop/:crop' => 'harvests#index', as: 'harvests_by_crop'

  resources :posts
  get '/posts/author/:author' => 'posts#index', as: 'posts_by_author'

  resources :scientific_names
  resources :alternate_names

  get 'crops/requested' => 'crops#requested', as: 'requested_crops'
  get 'crops/wrangle' => 'crops#wrangle', as: 'wrangle_crops'
  get 'crops/hierarchy' => 'crops#hierarchy', as: 'crops_hierarchy'
  get 'crops/search' => 'crops#search', as: 'crops_search'
  resources :crops do
    get 'photos' => 'photos#index'
    get 'sunniness' => 'charts/crops#sunniness'
    get 'planted_from' => 'charts/crops#planted_from'
    get 'harvested_for' => 'charts/crops#harvested_for'
  end

  resources :comments
  resources :roles
  resources :forums
  resources :notifications do
    get 'reply', on: :member
  end

  resources :follows, only: %i(create destroy)
  get '/members/:login_name/follows' => 'members#view_follows', as: 'member_follows'
  get '/members/:login_name/followers' => 'members#view_followers', as: 'member_followers'

  get '/places' => 'places#index'
  get '/places/search' => 'places#search', as: 'search_places'
  get '/places/:place' => 'places#show', as: 'place'

  resources :likes, only: %i(create destroy)

  get "home/index"
  root to: 'home#index'

  get 'auth/:provider/callback' => 'authentications#create'
  get 'members/auth/:provider/callback' => 'authentications#create'

  comfy_route :cms_admin, path: '/admin/cms'
  namespace :admin do
    resources :members
  end

  get '/admin' => 'admin#index'
  get '/admin/newsletter' => 'admin#newsletter', as: :admin_newsletter
  get '/admin/:action' => 'admin#:action'

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
  comfy_route :cms, path: '/', sitemap: false
end
