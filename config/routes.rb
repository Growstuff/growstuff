Growstuff::Application.routes.draw do

  get '/robots.txt' => 'robots#robots'

  resources :plant_parts

  devise_for :members, :controllers => { :registrations => "registrations", :passwords => "passwords" }
  devise_scope :member do 
    get '/members/unsubscribe/:message' => 'members#unsubscribe', :as => 'unsubscribe_member'
  end

  resources :members 

  resources :photos

  resources :authentications, :only => [:create, :destroy]

  resources :plantings
  get '/plantings/owner/:owner' => 'plantings#index', :as => 'plantings_by_owner'
  get '/plantings/crop/:crop' => 'plantings#index', :as => 'plantings_by_crop'

  resources :gardens
  get '/gardens/owner/:owner' => 'gardens#index', :as => 'gardens_by_owner'

  resources :seeds
  get '/seeds/owner/:owner' => 'seeds#index', :as => 'seeds_by_owner'
  get '/seeds/crop/:crop' => 'seeds#index', :as => 'seeds_by_crop'

  resources :harvests
  get '/harvests/owner/:owner' => 'harvests#index', :as => 'harvests_by_owner'
  get '/harvests/crop/:crop' => 'harvests#index', :as => 'harvests_by_crop'

  resources :posts
  get '/posts/author/:author' => 'posts#index', :as => 'posts_by_author'

  resources :scientific_names
  resources :alternate_names

  get 'crops/wrangle' => 'crops#wrangle', :as => 'wrangle_crops'
  get 'crops/hierarchy' => 'crops#hierarchy', :as => 'crops_hierarchy'
  get 'crops/search' => 'crops#search', :as => 'crops_search'
  resources :crops

  resources :comments
  resources :roles
  resources :forums
  resources :notifications do
    get 'reply', on: :member
  end

  resources :follows, :only => [:create, :destroy]
  get '/members/:login_name/follows' => 'members#view_follows', :as => 'member_follows'
  get '/members/:login_name/followers' => 'members#view_followers', :as => 'member_followers'


  get '/places' => 'places#index'
  get '/places/search' => 'places#search', :as => 'search_places'
  get '/places/:place' => 'places#show', :as => 'place'

  # everything for paid accounts etc
  resources :account_types
  resources :accounts
  resources :orders
  get 'orders/:id/checkout' => 'orders#checkout', :as => 'checkout_order'
  get 'orders/:id/complete' => 'orders#complete', :as => 'complete_order'
  get 'orders/:id/cancel' => 'orders#cancel', :as => 'cancel_order'

  resources :order_items
  resources :products

  get "home/index"
  root :to => 'home#index'

  get 'auth/:provider/callback' => 'authentications#create'


  get '/policy/:action' => 'policy#:action'

  get '/support' => 'support#index'
  get '/support/:action' => 'support#:action'

  get '/about' => 'about#index'
  get '/about/:action' => 'about#:action'

  get '/shop' => 'shop#index'
  get '/shop/:action' => 'shop#:action'

  comfy_route :cms_admin, :path => '/admin/cms'
  get '/admin/orders' => 'admin/orders#index'
  get '/admin/orders/:action' => 'admin/orders#:action'
  get '/admin' => 'admin#index'
  get '/admin/newsletter' => 'admin#newsletter', :as => :admin_newsletter
  get '/admin/:action' => 'admin#:action'

# CMS stuff  -- must remain LAST
  comfy_route :cms, :path => '/', :sitemap => false

end
