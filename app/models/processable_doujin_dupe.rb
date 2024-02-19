class ProcessableDoujinDupe < ApplicationRecord
  # ProcessableDoujin
  belongs_to :processable_doujin_parent, inverse_of: :processable_doujin_dupes_parents, foreign_key: :pd_parent_id, class_name: 'ProcessableDoujin'
  belongs_to :processable_doujin_child , inverse_of: :processable_doujin_dupes_childs , foreign_key: :pd_child_id , class_name: 'ProcessableDoujin', optional: true

  # Doujin
  belongs_to :processable_doujin       , inverse_of: :processable_doujin_dupes_parents, foreign_key: :pd_parent_id, class_name: 'ProcessableDoujin'
  belongs_to :doujin                   , inverse_of: :processable_doujin_dupes        , optional: true
end
