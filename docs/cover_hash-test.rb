# [-1].pack('q').unpack('Q').first

class CreateCoverHashes < ActiveRecord::Migration[8.0]
  def change
    create_table :cover_hashes do |t|
      t.references :parent, foreign_key: { to_table: :cover_hashes }
      t.integer :parent_distance

      # 256bit IDHash fingerprint in hexadecimal
      t.string :fingerprint, null: false, limit: 64

      # cache the number of child records to skip lookups
      t.integer :num_files, null: false, default: 0

      t.timestamps
    end

    add_index :cover_hashes, :fingerprint, unique: true
  end
end

class AddCoverHashIdToDoujinshi < ActiveRecord::Migration[8.0]
  def change
    add_reference :doujinshi            , :cover_hash
    add_reference :processable_doujinshi, :cover_hash
  end
end

class CoverHash < ApplicationRecord
  has_many :doujinshi
  has_many :processable_doujinshi

  belongs_to :parent, class_name: 'CoverHash', optional: true

  def fingerprint    = self[:fingerprint].to_i(16)
  def fingerprint=(v); self[:fingerprint] = v.to_s(16).rjust(64, '0'); end

  def distance(value) = DHashVips::IDHash.distance3(fingerprint, value)

  # https://en.wikipedia.org/wiki/BK-tree#Insertion
  # puts Benchmark.measure{ActiveRecord::Base.logger.silence{ m=('f'*64).to_i(16); 120_000.times{|i| print "#{i}\r"; CoverHash.bktree_add_node rand(m) } }}
  def self.bktree_add_node(value)
    if none?
      create! fingerprint: value  # create root node
    else
      u = find_by(parent_id: nil) # root node

      loop do
        k = u.distance value

        return u if k == 0

        v = find_or_initialize_by parent_id: u.id, parent_distance: k

        if v.new_record?
          v.update! fingerprint: value
          return v
        end

        u = v
      end
    end
  end # self.bktree_add_node

  # https://en.wikipedia.org/wiki/BK-tree#Lookup
  # max_distance = max different bits (max 256)
  #   h = rand(('f'*64).to_i(16))
  #   ActiveRecord::Base.logger.silence{
  #     Benchmark.bm(4){|x|
  #       10.times{|i|
  #         x.report("#{'%02d' % i}:"){ CoverHash.bktree_find_nodes h, max_distance: i }}}}
  def self.bktree_find_nodes(value, max_distance: 25)
    closest_nodes = []

    set = [ find_by(parent_id: nil) ] # initial set with root node only

    d_best = max_distance + 1
    n = 1
    while u = set.shift
      n+=1; print "#{n}\r"
      d = u.distance value

      if d < d_best
        d_best = d
        closest_nodes << u
      end

      set += where(parent_id: u.id).where("ABS(parent_distance - ?) < ?", d, d_best).all
    end

    puts "ITEMS: #{n} / #{count}"
    closest_nodes
  end # self.bktree_find_nodes
end
