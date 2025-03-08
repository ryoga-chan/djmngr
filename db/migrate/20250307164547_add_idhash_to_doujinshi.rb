class AddIdhashToDoujinshi < ActiveRecord::Migration[8.0]
  def change
    add_column :doujinshi            , :cover_idhash, :string, limit: 64
    add_column :deleted_doujinshi    , :cover_idhash, :string, limit: 64
    add_column :processable_doujinshi, :cover_idhash, :string, limit: 64
  end
end
