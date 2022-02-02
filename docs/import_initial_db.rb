#!/usr/bin/env ruby
$VERBOSE = nil

# load './docs/import_initial_db.rb'

# https://github.com/sparklemotion/sqlite3-ruby
%w{ sqlite3 pp progressbar }.each{|l| require l }

ActiveRecord::Base.logger.level = 1
pb_opts = {title: 'record', starting_at: 0, total: 100, progress_mark:  '#', remainder_mark: '_', length: 79, format: '%t: %J%% [%B] %e'}

@db = SQLite3::Database.new 'tmp.djdb/doujinshi.db'
@db.results_as_hash = true

# import THEMES
Author.transaction do
  tot = @db.execute("SELECT COUNT(1) AS n FROM themes")[0]['n'].to_i
  pb = ProgressBar.create pb_opts.merge(total: tot, title: 'themes')
  @db.execute("SELECT * FROM themes ORDER BY id").each do |r|
    pb.increment
    Theme.create! r.merge!(
      doujinshi_org_id:  r.delete('id').to_i,
      doujinshi_org_url: r.delete('url'),
      created_at:        r['updated_at'])
  end; nil
end
t_ids = {}; Theme .pluck(:id, :doujinshi_org_id).each{|id, did| t_ids[did] = id }; nil
# translate theme parent_id
Author.transaction do
  pb = ProgressBar.create pb_opts.merge(total: Theme.count, title: 'theme parents')
  Theme.where.not(parent_id: nil).pluck(:id, :parent_id).each do |t_id, p_did|
    pb.increment
    next unless t_ids[p_did]
    Author.connection.execute "UPDATE themes SET parent_id = #{t_ids[p_did]} WHERE id = #{t_id}"
  end; nil
end

# import CIRCLES
Author.transaction do
  tot = @db.execute("SELECT COUNT(1) AS n FROM circles")[0]['n'].to_i
  pb = ProgressBar.create pb_opts.merge(total: tot, title: 'circles')
  @db.execute("SELECT * FROM circles ORDER BY id").each do |r|
    pb.increment
    Circle.create! r.merge!(
      doujinshi_org_id:  r.delete('id').to_i,
      doujinshi_org_url: r.delete('url'),
      created_at:        r['updated_at'])
  end; nil
end
c_ids = {}; Circle.pluck(:id, :doujinshi_org_id).each{|id, did| c_ids[did] = id }; nil

# import AUTHORS
Author.transaction do
  tot = @db.execute("SELECT COUNT(1) AS n FROM authors")[0]['n'].to_i
  pb = ProgressBar.create pb_opts.merge(total: tot, title: 'authors')
  @db.execute("SELECT * FROM authors ORDER BY id").each do |r|
    pb.increment
    Author.create! r.merge!(
      doujinshi_org_id:  r.delete('id').to_i,
      doujinshi_org_url: r.delete('url'),
      created_at:        r['updated_at'])
  end; nil
end
a_ids = {}; Author.pluck(:id, :doujinshi_org_id).each{|id, did| a_ids[did] = id }; nil

# import authors_circles
Author.transaction do
  tot = @db.execute("SELECT COUNT(1) AS n FROM authors_circles")[0]['n'].to_i
  pb = ProgressBar.create pb_opts.merge(total: tot, title: 'authors_circles')
  @db.execute("SELECT * FROM authors_circles ORDER BY id").each do |r|
    pb.increment
    Author.connection.execute "INSERT INTO authors_circles (author_id, circle_id) "\
      "VALUES (#{a_ids[r['author_id'].to_i]}, #{c_ids[r['circle_id'].to_i]})"
  end; nil
  ts = @db.execute("SELECT * FROM authors_circles ORDER BY updated_at DESC LIMIT 1")[0]['updated_at']
  Author.connection.execute "UPDATE authors_circles SET created_at = '#{ts}'"
end

# import authors_themes
Author.transaction do
  tot = @db.execute("SELECT COUNT(1) AS n FROM authors_themes")[0]['n'].to_i
  pb = ProgressBar.create pb_opts.merge(total: tot, title: 'authors_themes')
  @db.execute("SELECT * FROM authors_themes ORDER BY id").each do |r|
    pb.increment
    Author.connection.execute "INSERT INTO authors_themes (author_id, theme_id) "\
      "VALUES (#{a_ids[r['author_id'].to_i]}, #{t_ids[r['theme_id'].to_i]})"
  end; nil
  ts = @db.execute("SELECT * FROM authors_themes ORDER BY updated_at DESC LIMIT 1")[0]['updated_at']
  Author.connection.execute "UPDATE authors_themes SET created_at = '#{ts}'"
end

# import circles_themes
Author.transaction do
  tot = @db.execute("SELECT COUNT(1) AS n FROM circles_themes")[0]['n'].to_i
  pb = ProgressBar.create pb_opts.merge(total: tot, title: 'circles_themes')
  @db.execute("SELECT * FROM circles_themes ORDER BY id").each do |r|
    pb.increment
    next unless t_ids[r['theme_id'].to_i]
    Author.connection.execute "INSERT INTO circles_themes (circle_id, theme_id) "\
      "VALUES (#{c_ids[r['circle_id'].to_i]}, #{t_ids[r['theme_id'].to_i]})"
  end; nil
  ts = @db.execute("SELECT * FROM circles_themes ORDER BY updated_at DESC LIMIT 1")[0]['updated_at']
  Author.connection.execute "UPDATE circles_themes SET created_at = '#{ts}'"
end

@db.close
