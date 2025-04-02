class AddCoverSdhashToDoujinshi < ActiveRecord::Migration[8.0]
  def change
    add_column :doujinshi            , :cover_sdhash, :integer
    add_column :deleted_doujinshi    , :cover_sdhash, :integer
    add_column :processable_doujinshi, :cover_sdhash, :integer
  end
end
