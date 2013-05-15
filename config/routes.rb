Growstuff::Application.routes.draw do

  resources :order_items


  devise_for :members, :controllers => { :registrations => "registrations" }

  resources :authentications
  resources :plantings
  resources :gardens
  resources :posts
  resources :scientific_names
  resources :crops
  resources :members
  resources :comments
  resources :roles
  resources :forums
  resources :notifications
  resources :orders
  resources :products

  get "home/index"

  match 'search/members/nearby' => 'members#nearby', :as => :nearby_members

  match 'auth/:provider/callback' => 'authentications#create'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  match '/policy/:action' => 'policy#:action'
  match '/support' => 'support#index'
  match '/support/:action' => 'support#:action'
  match '/about' => 'about#index'
  match '/about/:action' => 'about#:action'
  match '/shop' => 'shop#index'
  match '/shop/:action' => 'shop#:action'

end
