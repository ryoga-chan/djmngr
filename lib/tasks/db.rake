# https://unix.stackexchange.com/questions/86570/how-to-use-7z-to-compress-via-pipe
# compress/restore: cat file | xz -9 > file.7z --- 7za x -so x.sql.7z | sqlite3 x.db
def zip_databases(options = {})
  zipfile = Rails.root.join("tmp/db-#{Date.today}.7z").to_s
  
  Dir.mktmpdir('dbbkup_') do |tmpdir|
    db_sql = {}
    
    Dir["#{Rails.root}/db/#{Rails.env}*.sqlite3"].
      each{|db| db_sql[db] = "#{tmpdir.shellescape}/#{File.basename(db).sub /sqlite3$/, 'sql.7z'}" }
    
    print "Dumping #{db_sql.size} DBs: "
    p_passwd = "-p#{options[:passwd]}" if options[:passwd]
    db_sql.each do |db, sql_file|
      `(sqlite3 #{db.shellescape} .dump | 7za a -mx=9 -m0=PPMd:mem=64m -si #{p_passwd} #{sql_file.shellescape}) 2>&1`
      print $?.to_i == 0 ? '.' : 'X'
    end; puts ''
    
    File.unlink(zipfile) if File.exist?(zipfile)
    Dir.chdir(tmpdir){ `7za a -mx=0 #{zipfile.shellescape} .` } # create a single file
    puts "CREATED: #{zipfile} "
    
    yield(zipfile: zipfile, tmpdir: tmpdir) if block_given?
  end # mktmpdir
end # zip_databases ------------------------------------------------------------


# place this code in lib/tasks/db.rake
namespace :db do
  desc 'Archive all SQLITE databases'
  task(backup2zip: :environment){ zip_databases }

  # ----------------------------------------------------------------------------
  
  desc 'Vacuum SQLITE databases'
  task vacuum: :environment do
    Dir.chdir(Rails.root.join('db').to_s) do
      print "Vacuuming databases:"
      Dir['*.sqlite3'].each do |f|
        print " #{f}"
        system %Q|sqlite3 #{f} 'PRAGMA wal_checkpoint; vacuum;'|
      end
      puts " DONE!"
    end
  end # vacuuum
  
  # ----------------------------------------------------------------------------
  
  desc 'Copy SQLITE prod databases to test'
  task prod2test: :environment do
    Dir.chdir(Rails.root.join('db').to_s) do
      print "Copy prod DBs to test DBs: "
      Dir['production*.sqlite3'].each do |f|
        print " #{f}"
        dest = f.sub 'production', 'development'
        system %Q| cat #{f} > #{dest} |
        system %Q| sqlite3 #{dest} "UPDATE ar_internal_metadata SET value = 'development' WHERE key = 'environment'" |
      end
      puts " DONE!"
    end
  end # prod2test
  
  # ----------------------------------------------------------------------------
  
  desc 'Copy SQLITE test databases to prod'
  task test2prod: :environment do
    print "Are you sure DB TEST > PROD!??? [s|N] "
    exit if STDIN.gets.to_s[0] != 's'
    
    Dir.chdir(Rails.root.join('db').to_s) do
      print "Copy test DBs to prod DBs: "
      Dir['development*.sqlite3'].each do |f|
        print " #{f}"
        dest = f.sub 'development', 'production'
        system %Q| cat #{f} > #{dest} |
        system %Q| sqlite3 #{dest} "UPDATE ar_internal_metadata SET value = 'production' WHERE key = 'environment'" |
      end
      puts " DONE!"
    end
  end # test2prod
end
