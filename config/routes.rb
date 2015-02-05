Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  root to: 'static#index'
  scope 'api' do
    get '/stats/site_overview' => 'stats#site_overview'
    get '/auth/:provider/callback' => 'sessions#create'
    get '/sign_out' => 'sessions#destroy', as: :signout
    get '/current_user' => 'sessions#show'

    get '/variants' => 'variants#datatable'
    get '/variants/typeahead_results' => 'variants#typeahead_results', defaults: { format: :json }

    concern :audited do |options|
      get 'revisions/last' => "#{options[:controller]}#last"
      resources :revisions, { only: [:index, :show] }.merge(options)
    end

    concern :commentable do |options|
      resources :comments, { only: [:index, :show, :create, :update, :destroy] }.merge(options)
    end

    concern :moderated do |options|
      post 'suggested_changes/:id/accept' => "#{options[:controller]}#accept"
      post 'suggested_changes/:id/reject' => "#{options[:controller]}#reject"
      resources :suggested_changes, { only: [:index, :show, :create, :update] }.merge(options) do
        concerns :commentable, controller: 'moderation_comments'
      end
    end

    resources 'variant_groups', only: [:index, :show]

    resources 'genes', except: [:edit, :new], defaults: { format: :json } do
      concerns :audited, controller: 'gene_audits'
      concerns :moderated, controller: 'gene_moderations'
      concerns :commentable, controller: 'gene_comments'
      resources 'variants' do
        concerns :audited, controller: 'variant_audits'
        concerns :moderated, controller: 'variant_moderations'
        concerns :commentable, controller: 'variant_comments'
        resources 'evidence_items' do
          concerns :audited, controller: 'evidence_item_audits'
          concerns :moderated, controller: 'evidence_item_moderations'
          concerns :commentable, controller: 'evidence_item_comments'
        end
      end
    end
  end
  get '/auth/seed_admin' => 'sessions#seed_admin'
end
