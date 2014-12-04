Gluedb::Application.routes.draw do

  devise_for :users, :path => "accounts"

  root :to => 'dashboards#index'

  get "dashboards/index"
  get "welcome/index"
  get "tools/premium_calc"
  get "flatuipro_demo/index"

  post "policy_forms", :to => 'policies#create'

  namespace :admin do
    namespace :settings do
      resources :hbx_policies
    end
    resources :users
  end

  resources :enrollment_addresses

  resources :plan_metrics, :only => :index

  resources :vocab_uploads, :only => [:new, :create]
  resources :member_address_changes, :only => [:new, :create]
  resources :effective_date_changes, :only => [:new, :create]
  resources :mass_silent_cancels, :only => [:new, :create]
  resources :bulk_terminates, :only => [:new, :create]

  resources :enrollment_transmission_updates, :only => :create

  resources(:change_vocabularies, :only => [:new, :create]) do
    collection do
      get 'download'
    end
  end

  resources(:vocabulary_requests, :only => [:new, :create])

  resources :edi_transaction_set_payments
  resources :edi_transaction_sets
  resources :edi_transmissions

  resources :csv_transactions, :only => :show

  resources :enrollments do
    member do
      get :canonical_vocabulary
    end
  end

  resources :application_groups do
    member do
      get :applicant_links
    end
    resources :enrollments
    resources :enrollment_exemptions
    resources :eligibility_determinations
    resources :financial_statements
    resources :tax_households
    get 'page/:page', :action => :index, :on => :collection
  end

  resources :users

  resources :policies, only: [:new, :show, :create, :edit, :update] do
    member do
      get :cancelterminate
      post :transmit
    end
  end

  resources :individuals
  resources :people do
    resources :comments
    get 'page/:page', :action => :index, :on => :collection
    member do
      put :compare
      put :persist_and_transmit
      put :assign_authority_id
    end
  end

  resources :employers do
    get 'page/:page', action: :index, :on => :collection
    member do
      get :group
    end
    resources :employees, except: [:destroy], on: :member do
      member do
        put :compare
        put :terminate
      end
    end
  end

  resources :brokers do
    get 'page/:page', :action => :index, :on => :collection
  end

  resources :carriers do
    resources :plans
    get :show_plans
    get :plan_years
    post :calculate_premium, on: :collection
  end

  resources :plans, only: [:index, :show] do
    member do
      get :calculate_premium
    end
  end

  namespace :api, :defaults => { :format => 'xml' } do
    namespace :v1 do
      resources :events, :only => [:create]
      resources :people, :only => [:show, :index]
      resources :employers, :only => [:show, :index] do
        member do
          get :old_cv
        end
      end
      resources :policies, :only => [:show, :index]
      resources :application_groups, :only => [:show, :index]
      resources :households, :only => [:show, :index]
      resources :irs_reports, :only => [:index]
    end
    namespace :v2 do
      resources :events, :only => [:create]
      resources :people, :only => [:show, :index]
      resources :employers, :only => [:show, :index]
      resources :policies, :only => [:show, :index]
      resources :application_groups, :only => [:show, :index]
      resources :households, :only => [:show, :index]
      resources :irs_reports, :only => [:index]
      resources :plans, :only => [:show]
      resources :renewal_policies, :only => [:show]
    end
  end

  resources :special_enrollment_periods, only: [:new, :create]

  resources :carefirst_imports do
    collection do
      post 'update_policy_status'
      post 'update_enrollee_status'
    end
  end

  resources :carefirst_policy_updates, only: [:create] do
    collection do
      post 'upload_csv'
    end
  end

  namespace :soap do
    resources :individuals, :only => [] do
      collection do
        post 'get_by_hbx_id'
        get 'wsdl'
      end
    end
    resources :policies, :only => [] do
      collection do
        post 'get_by_policy_id'
        get 'wsdl'
      end
    end
    resources :application_groups, :only => [] do
      collection do
        post 'get_by_application_group_id'
        get 'wsdl'
      end
    end
    resources :employers, :only => [] do
      collection do
        post 'get_by_employer_id'
        get 'wsdl'
      end
    end
  end


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

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

end
