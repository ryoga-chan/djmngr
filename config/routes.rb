# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'home#index' # Defines the root path route ("/")
  
  get  'home/index'
  get  'home/settings'
  post 'home/settings'
  get  'home/info'
  
  get  'ws/ehentai'

  resources :process, only: %i[ index edit ] do
    collection do
      get     :show_externally
      get     :prepare_archive  # prepare processing of single file
      delete  :delete_archive
      post    :prepare_batch    # prepare mass processing of selected files
      post    :batch_delete     # delete selected files
      get     :sample_images
      get     :compare_add
      get     :compare_remove
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
      get     :batch            # start/monitor mass processing
      post    :batch            # change entry title in the batch
      delete  :batch            # remove entry from batch or the entire batch
      get     :read , to: 'doujinshi#zip_read' , model: 'ProcessableDoujin'
      get     :image, to: 'doujinshi#zip_image', model: 'ProcessableDoujin'
      get     :process_later
      post    :add_files
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
      get  :compare
      get  :zip_select4read
      get  :zip_read
      get  :zip_image
      get  :js_finder
    end
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

  resources :shelves, except: %i[ new create ] do
    get  :random, on: :collection
  end
end
