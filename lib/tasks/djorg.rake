# encryption reference:
#   https://stackoverflow.com/questions/11044324/how-to-encrypt-files-with-ruby
#   https://ruby-doc.com/stdlib/libdoc/openssl/rdoc/OpenSSL/Cipher.html#class-OpenSSL::Cipher-label-Encrypting+and+decrypting+some+data

# bin/rails djorg:metadata:dump RAILS_ENV=production
# bin/rails djorg:metadata:load RAILS_ENV=production
namespace :djorg do
  namespace :metadata do
    desc 'Load doujinshi.org metadata'
    task load: :environment do
      puts "Loading doujinshi.org metadata to #{Rails.env}:"
      
      raise 'no import/metadata.dat file found!' unless File.exist?('import/metadata.dat')
      
      Dir.mktmpdir do |tmpd|
        # decrypt file with app's master key
        cipher = OpenSSL::Cipher.new('aes-256-cbc')
        cipher.decrypt
        cipher.key = Rails.application.credentials.key
        cipher.iv  = Rails.application.credentials.key[8...24].reverse
        File.open(File.join(tmpd, 'metadata.zip'), 'wb') do |fout|
          File.open('import/metadata.dat', 'rb') do |fin|
            buffer = ""
            fout << cipher.update(buffer) while fin.read(1.megabyte, buffer)
            fout << cipher.final
          end
        end
        
        # unzip datasets
        system %Q| unzip -qq metadata.zip |, chdir: tmpd
        raise 'unzip error!' if $?.to_i != 0
        
        ids = { 'author' => {}, 'circle' => {}, 'theme' => {} }
        
        # load main tables and map new ids
        ids.keys.each do |k|
          fname = File.join(tmpd, "#{k.downcase}.jl")
          model = k.capitalize.constantize
          pb    = Enumerable.create_progressbar File.foreach(fname).inject(0){|c,l| c+1 }, k
          
          ActiveRecord::Base.logger.silence do
            ApplicationRecord.transaction do
              File.foreach(fname) do |l|
                attrs = JSON.parse l
                item  =  model.new attrs
                item.save validate: false
                ids[k][ attrs['id'] ] = item.id
                pb.increment
              end
            end # transaction
          end # silence log
        end
      
        # load relations
        %w{ authors_circles authors_themes circles_themes }.each do |k|
          fields = k.split('_').map(&:singularize)
          
          ActiveRecord::Base.logger.silence do
            ApplicationRecord.transaction do
              JSON.load_file(File.join(tmpd, "#{k}.json")).each_with_pb(title: k) do |row|
                q_fields = fields.map{|i| "#{i}_id" }.join(', ')
                q_values = fields.map{|i| ids[i][row["#{i}_id"].to_i] }.join(',')
                
                ApplicationRecord.connection.execute %Q| INSERT INTO #{k} (#{q_fields}) VALUES (#{q_values}) |
              end
            end # transaction
          end # silence log
        end
        
        FileUtils.mv 'import/metadata.dat', 'import/metadata.dat.imported', force: true
      end # mktmpdir
    end # load

    # ----------------------------------------------------------------------------
    
    desc 'Dump doujinshi.org imported metadata'
    task dump: :environment do
      puts "Dumping doujinshi.org metadata from #{Rails.env}:"
      
      Dir.mktmpdir do |tmpd|
        excluded_columns = %w{ created_at updated_at favorite faved_at doujinshi_org_aka_id notes }

        # dump main tables
        %w{ Author Circle Theme }.each do |k|
          File.open(File.join(tmpd, "#{k.downcase}.jl"), 'w') do |f|
            k.constantize.where.not(doujinshi_org_id: nil).each_with_pb(title: k) do |i, pb|
              f.puts i.attributes.slice!(*excluded_columns).to_json
            end; nil
          end
        end

        # dump relations
        %w{ authors_circles authors_themes circles_themes }.each do |k|
          fields = k.split('_').map(&:singularize)
          
          File.open(File.join(tmpd, "#{k}.json"), 'w') do |f|
            query = %Q[ SELECT #{fields.map{|i| "#{i}_id" }.join(', ')} FROM #{k} ]
            # add joins
            query += fields.map{|i| %Q[ INNER JOIN #{i}s ON #{i}s.id = #{i}_id ] }.join(' ')
            # add conditions
            query += ' WHERE ' + fields.map{|i| %Q[ #{i}s.doujinshi_org_id IS NOT NULL ] }.join(' AND ')

            f.puts ApplicationRecord.connection.select_all(query).to_json
          end
        end

        # zip every dataset
        system %Q| zip -9 metadata.zip *.jl *.json |, chdir: tmpd
        raise 'zip error!' if $?.to_i != 0

        # encrypt file with app's master key
        cipher = OpenSSL::Cipher::AES.new(256, :CBC)
        cipher.encrypt
        cipher.key = Rails.application.credentials.key
        cipher.iv  = Rails.application.credentials.key[8...24].reverse
        File.open(Rails.root.join('metadata.dat').to_s, 'wb') do |fout|
          File.open(File.join(tmpd, 'metadata.zip'), 'rb') do |fin|
            buffer = ""
            fout << cipher.update(buffer) while fin.read(1.megabyte, buffer)
            fout << cipher.final
          end
        end
        
        puts "file [metadata.dat] created"
      end
    end # dump
  end
end
