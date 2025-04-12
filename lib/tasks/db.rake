namespace :db do
  desc 'Archive sqlite database'
  task :backup2zip do
    require_relative '../../app/lib/db_dumper'
    print "Dumping DB... "
    puts "CREATED: #{DbDumper.dump}"
  end

  # ----------------------------------------------------------------------------

  desc 'Vacuum sqlite database'
  task :vacuum do
    db_file = Rails.root.join('storage', "production.sqlite3").to_s
    print "Vacuuming database... "
    system %Q( sqlite3 #{db_file.shellescape} 'vacuum;' )
    puts "DONE!"
  end # vacuuum

  # ----------------------------------------------------------------------------

  desc 'Copy sqlite prod database to test'
  task :prod2test do
    Rake::Task["db:vacuum"].invoke

    db_prod = Rails.root.join('storage', 'production.sqlite3' ).to_s
    db_test = Rails.root.join('storage', 'development.sqlite3').to_s

    print "Copying prod DB to test DB... "
    Dir["#{db_test}*"].each{|f| File.unlink f }
    FileUtils.cp db_prod, db_test
    system %Q( sqlite3 #{db_test.shellescape} "UPDATE ar_internal_metadata SET value = 'development' WHERE key = 'environment'" )
    puts "DONE!"
  end # prod2test
end
