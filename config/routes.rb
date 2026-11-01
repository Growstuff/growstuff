# frozen_string_literal: true

Rails.application.routes.draw do
  get '/api-docs/v1/swagger.json', to: 'api/docs#show', defaults: { format: :json }
  mount Rswag::Ui::Engine => '/api-docs'
  get '/robots.txt' => 'robots#robots'
  get '/dont-crawl-me' => proc { [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']] }

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
    post '/members/regenerate_api_token' => 'registrations#regenerate_api_token', as: 'regenerate_api_token'
    delete '/members/destroy_api_token' => 'registrations#destroy_api_token', as: 'destroy_api_token'
  end
  match '/members/:id/finish_signup' => 'members#finish_signup', via: %i(get patch), as: :finish_signup

  resources :authentications, only: %i(create destroy) do
    get :connected, on: :collection
  end

  get Atproto::ClientConfig::METADATA_PATH => 'oauth_client_metadata#show', as: :oauth_client_metadata

  get "home/index"
  get '/community-gardens', to: 'home#community_gardens'
  get '/releases', to: 'home#releases', as: :releases
  patch '/my/location', to: 'member_locations#update', as: :member_location
  patch '/my/name', to: 'member_names#update', as: :member_name
  patch '/my/email', to: 'member_emails#update', as: :member_email
  post '/my/email/decline', to: 'member_emails#decline', as: :decline_member_email
  post '/my/email/resend', to: 'member_emails#resend', as: :resend_member_email
  get '/suggestions', to: 'suggestions#index', as: :suggestions
  patch '/my/suggestions', to: 'suggestions#update', as: :my_suggestions
  post '/my/dismissed_crops', to: 'crop_dismissals#create', as: :crop_dismissals
  delete '/my/dismissed_crops', to: 'crop_dismissals#destroy_all'
  get '/my/neighbours', to: 'neighbours#show', as: :neighbours
  get '/my/neighbours/feed', to: 'neighbours#feed', as: :neighbours_feed
  post '/my/dismissed_members', to: 'member_dismissals#create', as: :member_dismissals
  root to: 'home#index'

  concern :has_photos do
    resources :photos, only: :index
  end

  # Before the gardens resource, so "nursery" isn't taken for a garden's slug.
  # Opening and closing your own garden stall.
  resource :stall, only: [] do
    resource :opening, only: %i(create destroy), module: :stalls
  end

  resource :nursery, only: %i(show create) do
    get :panel
    resource :decline, only: :create, module: :nurseries
  end

  resources :gardens, concerns: :has_photos, param: :slug do
    get 'timeline' => 'charts/gardens#timeline', constraints: { format: 'json' }
    post 'fetch_wikidata' => 'gardens#fetch_wikidata', on: :member
    post 'make_nursery' => 'gardens#make_nursery', on: :member
    post 'stop_nursery' => 'gardens#stop_nursery', on: :member

    resources :garden_collaborators
    resource :location, only: :update, controller: 'garden_locations'
  end

  # What the record harvest and save seeds dialogs offer to choose from.
  get 'planting_picker' => 'planting_pickers#show', as: :planting_picker

  resources :plantings, concerns: :has_photos, param: :slug do
    resources :harvests
    resources :seeds
    collection do
      get 'crop/:crop' => 'plantings#index', as: 'plantings_by_crop'
    end
    member do
      post :transplant
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
    post :preview, on: :collection
    get :link_suggestions, on: :collection
  end

  resources :scientific_names do
    collection do
      get :gbif_suggest
    end
  end
  resources :alternate_names
  resources :plant_parts
  resources :photos

  resources :photo_associations, only: %i(update destroy)

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
    post :gbif
    get :sowing_info, on: :member

    collection do
      get 'requested'
      get 'wrangle'
      get 'hierarchy'
      get 'search'
      get 'data_improvement'
    end
  end

  namespace :admin do
    resources :crops, only: [:index]
    resources :versions, only: [] do
      post :revert, on: :member, as: :revert
    end
  end

  resources :comments
  resources :forums

  resources :follows, only: %i(create destroy)
  resources :blocks, only: %i(create destroy)

  post 'likes' => 'likes#create'
  delete 'likes' => 'likes#destroy'

  # The timeline became the friends and neighbours page.
  get '/timeline', to: redirect('/my/neighbours')

  resources :members, param: :slug do
    resource :stall, only: :show
    # Before the gardens resource, so "inactive" isn't taken for a garden's slug.
    get 'gardens/inactive' => 'gardens#inactive', as: :inactive_gardens
    # param: :slug to match the top-level gardens resource, so the controller's
    # load_and_authorize_resource (id_param: :slug) finds the garden here too.
    resources :gardens, param: :slug do
      member do
        get 'layout', to: 'gardens#layout'
        # Same URL, saving the whole arrangement at once. See GardensController#update_layout.
        patch 'layout', to: 'gardens#update_layout', as: :update_layout
      end
    end
    resources :seeds
    resources :plantings
    resources :harvests
    resources :posts
    resources :jobs, except: :show

    resources :follows
    get 'followers' => 'follows#followers'
    resources :blocks, only: %i(create destroy)
  end

  resources :messages
  get 'jobs/suggestions' => 'job_suggestions#index', as: :job_suggestions
  resources :job_ideas, only: %i(index create) do
    post :hide, on: :collection
  end
  resources :jobs, param: :slug, except: :show
  resources :conversations do
    collection do
      delete 'destroy_multiple'
    end
  end

  resources :places, only: %i(index show), param: :place do
    get 'search', on: :collection
    get 'suggest', on: :collection
  end

  get 'auth/:provider/callback' => 'authentications#create'
  get 'members/auth/:provider/callback' => 'authentications#create'

  scope :admin do
    get '/' => 'admin#index', as: 'admin'
  end

  namespace :admin do
    resources :members, param: :slug do
      post :bulk_ban, on: :collection
      post :restore, on: :member
    end
    resources :roles
    resources :features, only: %i(index update)
    resources :reminder_stats, only: :index
    resources :job_templates, only: :index
    resources :crops, param: :slug do
      resources :crop_companions
      resources :crop_job_templates, path: 'job_templates', except: :show
    end
  end

  # What can be done to each is declared by its resource, which is also where the API docs read it from.
  scope path: ApplicationResource.endpoint_namespace, module: 'api/v1', as: :api_v1, defaults: { format: :jsonapi } do
    get 'crops/search', to: 'crops#search'
    [CropResource, GardenResource, HarvestResource, JobResource,
     MemberResource, PhotoResource, PlantingResource, SeedResource].each do |resource|
      resources resource.type, only: resource.endpoint[:actions]
    end
  end

  get '/.well-known/acme-challenge/:id' => 'pages#letsencrypt'

  get '/about' => 'pages#about', as: :about
  get '/policy' => 'pages#policies', as: :policies
  get '/policy/tos' => 'pages#tos', as: :policy_tos
  get '/policy/privacy' => 'pages#privacy', as: :policy_privacy
  get '/policy/api' => 'pages#data_use', as: :policy_data_use
  get '/policy/community' => 'pages#community_guidelines', as: :policy_community
  get '/policy/copyright' => 'pages#copyright', as: :policy_copyright
  get '/support' => 'pages#support', as: :support
  get '/about/contact' => 'pages#contact', as: :contact
end
