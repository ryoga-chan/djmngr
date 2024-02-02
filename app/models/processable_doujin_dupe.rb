class ProcessableDoujinDupe < ApplicationRecord
  belongs_to :processable_doujin_parent, foreign_key: :pd_parent_id, class_name: 'ProcessableDoujin', inverse_of: :processable_doujin_dupes_parents
  belongs_to :processable_doujin_child , foreign_key: :pd_child_id , class_name: 'ProcessableDoujin', inverse_of: :processable_doujin_dupes_childs
end
