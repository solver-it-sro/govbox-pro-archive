Rails.application.routes.draw do


  namespace :settings do
    resources :automation_rules
    resource :automation_rule do
      post 'header_step'
      patch 'header_step'
      post 'conditions_step'
      patch 'conditions_step'
      post 'actions_step'
      patch 'actions_step'
    end
    resources :automation_conditions, param: :index do
      post '/', to: 'automation_conditions#edit', on: :member
    end
    resources :automation_actions, param: :index do
      post '/', to: 'automation_actions#edit', on: :member
    end
    resources :tags
    resource :profile
  end

  namespace :admin do
    resources :tenants do
      resources :groups
      resources :users
      resources :boxes
      resources :tags
    end

    resources :group_memberships
    resources :tag_users
  end

  resources :boxes, path: 'schranky', only: [:index, :show] do
    post :sync
  end

  resources :tags do
    resources :message_threads do
    end
  end

  resources :message_threads do
    collection do
      get 'merge'
    end
    resources :messages
  end
  resources :message_threads_tags

  resources :messages do
    member do
      post 'authorize_delivery_notification'
    end

    resources :message_objects do
      member do
        get 'download'
      end
    end
  end

  resources :message_drafts do
    member do
      post 'submit'
    end
  end

  resources :messages_tags

  resource :settings

  namespace :drafts, path: 'drafty' do
    resources :imports, path: 'importy', only: :create do
      get :upload_new, path: 'novy', on: :collection
    end
  end

  resources :drafts, path: 'drafty', only: %i[index show destroy] do
    post :submit
    post :submit_all, on: :collection
  end

  resources :sessions do
    get :login, on: :collection
    delete :destroy, on: :collection
  end

  get :auth, path: 'prihlasenie', to: 'sessions#login'
  get 'auth/google_oauth2/callback', to: 'sessions#create'
  get 'auth/google_oauth2/failure', to: 'sessions#failure'

  root 'dashboard#show'

  class GoodJobAdmin
    def self.matches?(request)
      User.find(request.session['user_id'])&.site_admin?
    end
  end

  constraints(GoodJobAdmin) do
    mount GoodJob::Engine => 'good_job'
  end
end
