# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'home#index' # Defines the root path route ("/")
  
  get  'home/index'
  get  'home/settings'
  post 'home/settings'
  
  resources :process, only: %i[ index edit ] do
    collection do
      get     :show_externally
      get     :prepare_archive  # prepare processing of single file
      delete  :delete_archive
      post    :prepare_batch    # prepare mass processing of selected files
    end
    member do
      get     :show_image
      post    :rename_file
      post    :rename_images
      post    :set_property
      post    :finalize_volume
      get     :finalize_volume
      delete  :delete_archive_cwd
      delete  :delete_archive_files
      get     :edit_cover
      get     :inspect_folder
      get     :batch            # manage mass processing
      delete  :batch
    end
  end # process

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
    end
    member do
      get  :read
      get  :image
      get  :delete
      post :read_pages
      post :score
      post :rehash
      post :reprocess
      get  :shelf
    end
  end
  
  concern :metadata_crud do
    collection do
      get  :djorg_dl
      get  :tags_lookup
    end
    member do
      get  :djorg_alias_check
    end
  end
  resources :authors, concerns: :metadata_crud
  resources :circles, concerns: :metadata_crud
  resources :themes , concerns: :metadata_crud

  resources :shelves, except: %i[ new create ]
end
