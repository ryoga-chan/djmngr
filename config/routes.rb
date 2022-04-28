# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'home#index' # Defines the root path route ("/")
  
  get 'home/index'
  
  resources :process, only: %i[ index edit ] do
    collection do
      get     :prepare_archive
      delete  :delete_archive
    end
    
    member do
      get     :show_image
      post    :rename_file
      post    :rename_images
      post    :set_property
      post    :finalize_volume
      delete  :delete_archive_cwd
      delete  :delete_archive_files
    end
  end # process

  resources :doujinshi, except: %i[ new create ] do
    collection do
      get  :epub
    end
    
    member do
      get  :read
      post :read_pages
      get  :image
      get  :delete
      post :score
    end
  end
  resources :authors
  resources :circles
  resources :themes
end
