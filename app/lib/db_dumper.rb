module DbDumper
  FPRINT_FILE = Rails.root.join('tmp', 'db-periodic_dump.stats').to_s

  # create dump of production DB and return the file name
  #   - dump   : sqlite3 db.sqlite3 .dump | zstd -6 > db.sql.zst
  #   - restore: unzstd db.sql.zst | sqlite3 db.sqlite3
  def self.dump
    src = Rails.root.join('storage', 'production.sqlite3').to_s
    dst = Rails.root.join('storage', "db-#{Time.now.strftime '%F_%H-%M'}.sql.zst").to_s
    `(sqlite3 #{src.shellescape} .dump | zstd -6 > #{dst.shellescape}) 2>&1`
    dst
  end # self.dump

  # remove old dumps
  def self.clean
    src = Rails.root.join('storage', 'db-*.sql.zst').to_s
    Dir[src].sort[...-8].each{|f| FileUtils.rm_f f }
  end # self.clean

  def self.db_fingerprint
    src = Rails.root.join('storage', 'production.sqlite3*').to_s

    Dir[src].map{|f|
      s = File.stat f
      "#{s.size}@#{s.mtime.to_i}"
    }.join("|")
  end # self.db_fingerprint

  # periodically dump DB
  def self.periodic_dump
    Thread.new{
      File.write FPRINT_FILE, db_fingerprint

      loop {
        sleep(Time.now.tomorrow.at_midnight + 4.hours - Time.now) # wait till 4AM

        f1 = File.read FPRINT_FILE
        f2 = db_fingerprint

        if f1 != f2
          File.write FPRINT_FILE, f2
          dump
          clean
        end
      }# loop
    }# Thread.new
  end # self.periodic_dump
end # DbDumper
