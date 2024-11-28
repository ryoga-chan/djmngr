Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'home#index' # Defines the root path route ("/")

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get  "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get  "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get  "manifest"       => "rails/pwa#manifest"      , as: :pwa_manifest
  
  get  'home/index'
  get  'home/settings'
  post 'home/settings'
  get  'home/info'
  post "shared_content_receiver" => 'home#shared_content_receiver'

  get  'ws/ehentai'
  get  'ws/to_romaji'
  get  'ws/dl_image'
  post 'ws/dl_image'

  resources :process, only: %i[ index edit ] do
    collection do
      get     :show_externally
      get     :prepare_archive  # prepare processing of single file
      delete  :delete_archive
      post    :prepare_batch    # prepare mass processing of selected files
      post    :batch_delete     # delete selected files
      post    :batch_merge      # process selected files into a single folder
      get     :sample_images
      get     :clear
      get     :compare_add
      get     :compare_remove
    end # collection
    member do
      get     :show_image
      post    :rename_file
      post    :rename_images
      post    :set_property
      post    :finalize_volume
      get     :finalize_volume
      delete  :delete_archive_cwd
      delete  :delete_archive_files
      post    :split_archive
      get     :edit_cover
      get     :inspect_folder
      get     :batch            # start/monitor mass processing
      post    :batch            # change entry title in the batch
      delete  :batch            # remove entry from batch or the entire batch
      get     :read , to: 'doujinshi#zip_read' , model: 'ProcessableDoujin'
      get     :image, to: 'doujinshi#zip_image', model: 'ProcessableDoujin'
      get     :process_later
      post    :add_files
      delete  :group_rm
      post    :pd_notes
    end # member
  end # resources :process

  resources :doujinshi, except: %i[ new create ] do
    collection do
      get  :epub
      get  :fav_toggle
      get  :favorites
      get  :search
      post :search_cover
      get  :search_cover
      get  :scored
      get  :random_pick
      get  :compare
      get  :zip_select4read
      get  :zip_read
      get  :zip_image
      get  :js_finder
      post :move
    end # collection
    member do
      get  :read , to: 'doujinshi#zip_read' , model: 'Doujin'
      get  :image, to: 'doujinshi#zip_image', model: 'Doujin'
      get  :delete
      post :read_pages
      post :score
      post :rehash
      post :reprocess
      get  :shelf
      get  :compare_add
    end # member
  end # resources :doujinshi

  concern :metadata_crud do
    collection do
      get  :djorg_dl
      get  :tags_lookup
    end # collection
    member do
      get  :djorg_alias_check
    end # member
  end # concern :metadata_crud
  resources :authors, concerns: :metadata_crud
  resources :circles, concerns: :metadata_crud
  resources :themes , concerns: :metadata_crud

  resources :shelves, except: %i[ new create ] do
    get  :random, on: :collection
  end # resources :shelves
end
