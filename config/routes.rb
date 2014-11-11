Growstuff::Application.routes.draw do

  resources :follows

  resources :plant_parts

  devise_for :members, :controllers => { :registrations => "registrations", :passwords => "passwords" }

  resources :members

  resources :photos

  resources :authentications

  resources :plantings
  match '/plantings/owner/:owner' => 'plantings#index', :as => 'plantings_by_owner'
  match '/plantings/crop/:crop' => 'plantings#index', :as => 'plantings_by_crop'

  resources :gardens
  match '/gardens/owner/:owner' => 'gardens#index', :as => 'gardens_by_owner'

  resources :seeds
  match '/seeds/owner/:owner' => 'seeds#index', :as => 'seeds_by_owner'
  match '/seeds/crop/:crop' => 'seeds#index', :as => 'seeds_by_crop'

  resources :harvests
  match '/harvests/owner/:owner' => 'harvests#index', :as => 'harvests_by_owner'
  match '/harvests/crop/:crop' => 'harvests#index', :as => 'harvests_by_crop'

  resources :posts
  match '/posts/author/:author' => 'posts#index', :as => 'posts_by_author'

  resources :scientific_names
  resources :alternate_names

  match 'crops/wrangle' => 'crops#wrangle', :as => 'wrangle_crops'
  match 'crops/hierarchy' => 'crops#hierarchy', :as => 'crops_hierarchy'
  match 'crops/search' => 'crops#search', :as => 'crops_search'
  resources :crops

  resources :comments
  resources :roles
  resources :forums
  resources :notifications

  get '/places' => 'places#index'
  get '/places/search' => 'places#search', :as => 'search_places'
  get '/places/:place' => 'places#show', :as => 'place'

  # everything for paid accounts etc
  resources :account_types
  resources :accounts
  resources :orders
  match 'orders/:id/checkout' => 'orders#checkout', :as => 'checkout_order'
  match 'orders/:id/complete' => 'orders#complete', :as => 'complete_order'
  match 'orders/:id/cancel' => 'orders#cancel', :as => 'cancel_order'

  resources :order_items
  resources :products

  get "home/index"
  root :to => 'home#index'

  match 'auth/:provider/callback' => 'authentications#create'


  match '/policy/:action' => 'policy#:action'

  match '/support' => 'support#index'
  match '/support/:action' => 'support#:action'

  match '/about' => 'about#index'
  match '/about/:action' => 'about#:action'

  match '/shop' => 'shop#index'
  match '/shop/:action' => 'shop#:action'

  match '/admin/orders' => 'admin/orders#index'
  match '/admin/orders/:action' => 'admin/orders#:action'
  match '/admin' => 'admin#index'
  match '/admin/newsletter' => 'admin#newsletter', :as => :admin_newsletter
  match '/admin/:action' => 'admin#:action'

  

end
