class AddCoverSdhashToDoujinshi < ActiveRecord::Migration[8.0]
  def change
    remove_column :doujinshi            , :cover_idhash
    remove_column :deleted_doujinshi    , :cover_idhash
    remove_column :processable_doujinshi, :cover_idhash
    
    add_column :doujinshi            , :cover_sdhash, :integer
    add_column :deleted_doujinshi    , :cover_sdhash, :integer
    add_column :processable_doujinshi, :cover_sdhash, :integer
  end
end
