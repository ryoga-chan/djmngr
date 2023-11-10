# place this code in lib/tasks/db.rake
namespace :db do
  desc 'Archive sqlite database'
  task :backup2zip do
    db_file  = Rails.root.join('db', 'production.sqlite3').to_s
    zip_file = Rails.root.join("db-#{Time.now.strftime '%F_%H-%M'}.sql.7z").to_s
    
    print "Dumping DB... " # restore with: 7za x -so db.sql.7z | sqlite3 db.sqlite3
    `(sqlite3 #{db_file.shellescape} .dump | 7za a -mx=9 -m0=PPMd:mem=64m -si #{zip_file.shellescape}) 2>&1`
    
    puts "CREATED: #{zip_file}"
  end

  # ----------------------------------------------------------------------------
  
  desc 'Vacuum sqlite database'
  task :vacuum do
    db_file = Rails.root.join('db', "production.sqlite3").to_s
    print "Vacuuming database... "
    system %Q| sqlite3 #{db_file.shellescape} 'vacuum;' |
    puts "DONE!"
  end # vacuuum
  
  # ----------------------------------------------------------------------------
  
  desc 'Copy sqlite prod database to test'
  task :prod2test do
    Rake::Task["db:vacuum"].invoke

    db_prod = Rails.root.join('db', 'production.sqlite3' ).to_s
    db_test = Rails.root.join('db', 'development.sqlite3').to_s

    print "Copying prod DB to test DB... "
    Dir["#{db_test}*"].each{|f| File.unlink f }
    FileUtils.cp db_prod, db_test
    system %Q| sqlite3 #{db_test.shellescape} "UPDATE ar_internal_metadata SET value = 'development' WHERE key = 'environment'" |
    puts "DONE!"
  end # prod2test
end
