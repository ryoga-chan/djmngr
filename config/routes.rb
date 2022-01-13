# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'home#index' # Defines the root path route ("/")
  
  get 'home/index'
  
  resources :process, only: [:index, :edit] do
    collection do
      get     :prepare_archive
      delete  :delete_archive
    end
    
    member do
      post    :rename_image
      post    :rename_images
      delete  :delete_archive_cwd
      delete  :delete_archive_files
    end
  end
end
