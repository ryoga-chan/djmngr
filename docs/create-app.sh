#!/bin/bash
rm -rf djmngr
bin/rails new djmngr --rc=railsrc

bin/rails g scaffold author name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text
bin/rails g scaffold circle name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text
bin/rails g scaffold theme  name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text parent_id:integer
bin/rails g migration create_authors_circles author:references circle:references
bin/rails g migration create_authors_themes  author:references theme:references
bin/rails g migration create_circles_themes  circle:references theme:references

bin/rails g scaffold doujin name:string name_romaji:string name_kakasi:string \
  size:integer checksum:string num_images:integer num_files:integer score:integer \
  file_folder:text file_name:text name_orig:text string:category
bin/rails g migration create_authors_doujinshi author:references doujin:references
bin/rails g migration create_circles_doujinshi circle:references doujin:references

bin/rails g job process_archive_decompress
bin/rails g job process_archive_compress
bin/rails g job process_index_refresh
bin/rails g job process_batch
bin/rails g job process_batch_inspect
bin/rails g job cover_matching

wget -O config/locales/en.yml https://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/en.yml

bin/rails g paper_trail:install --with-changes

bin/rails g model deleted_doujin \
  name:string name_kakasi:string alt_name:string alt_name_kakasi:string \
  size:integer num_images:integer num_files:integer doujin_id:integer

bin/rails g model processable_doujin name:string name_kakasi:string size:integer

bin/rails g scaffold shelf name:string
bin/rails g model doujin_shelf doujin:references shelf:references position:integer

# https://github.com/SortableJS/Sortable
# https://github.com/SortableJS/jquery-sortablejs
wget -O app/assets/javascripts/sortable.js        https://cdn.jsdelivr.net/npm/sortablejs@latest/Sortable.js
wget -O app/assets/javascripts/jquery-sortable.js https://cdn.jsdelivr.net/npm/jquery-sortablejs@latest/jquery-sortable.js
wget -O app/assets/javascripts/freezeframe.js     https://cdn.jsdelivr.net/npm/freezeframe@latest/dist/freezeframe.min.js

bin/rails db:migrate
bin/rails db:schema:dump
bin/rails db:erd          # create DB graph (see lib/tasks/erd.rake)

# create `config/favicon.json` from https://realfavicongenerator.net/favicon/ruby_on_rails
# and place the master image in app/assets/images/master_favicon.jpg
rails g favicon
echo "//= link favicon/browserconfig.xml" >> app/assets/config/manifest.js

bin/rails assets:clobber
bin/rails assets:precompile
bin/server -p

bin/rails g controller ws ehentai

bin/rails g model processable_doujin_dupe pd_parent_id:integer pd_child_id:integer likeness:integer

bin/rails g migration add_cover_idhash_to_doujinshi cover_idhash:string

bin/rails g migration add_cover_sdhash_to_doujinshi cover_sdhash:integer
Doujin.transaction{ Doujin.find_each.with_index{|d, i| print "#{i}\r"; d.cover_fingerprint! }};puts ''
Doujin.transaction{ ProcessableDoujin.find_each.with_index{|d, i| print "#{i}\r"; d.cover_fingerprint! }};puts ''
ProcessableDoujinDupe.delete_all
ProcessIndexGroupJob.perform_now

bin/rails g migration add_startup_to_settings startup:boolean
