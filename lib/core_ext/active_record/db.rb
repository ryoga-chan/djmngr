# https://stackoverflow.com/questions/13173618/truncate-tables-with-rails-console/13173994#13173994
module CoreExt::ActiveRecord::Db
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def truncate_and_restart_sequence
      delete_all
      connection.execute %Q|UPDATE SQLITE_SEQUENCE SET seq = 0 WHERE name = '#{table_name}'|
    end # truncate_and_restart_sequence
  end # ClassMethods
end

ActiveRecord::Base.send :include, CoreExt::ActiveRecord::Db
