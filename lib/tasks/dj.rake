require 'optparse'

# bin/rails dj:process -- ...
namespace :dj do
  desc 'process a doujin'
  task process: :environment do |args|
    def die(msg, code = 1); puts msg; exit code; end
  
    options = { overwrite: false }
    
    ARGV.shift # discard "--"
    
    OptionParser.new do |op|
      op.banner = '' # Set a banner, displayed at the top of the help screen.
      
      op.on("-o", "--overwrite", "overwrite destination doujin"){ options[:overwrite] = true }
      
      op.on("-n filename", "--name {filename}", "use a custom file name", String) do |v|
        die "empty filename" if v.blank?
        options[:dest_filename] = v
      end # --title
      
      op.on("-k", "--keep-filename", "keep filename"){ options[:keep_filename] = true }
      
      op.on("-s score", "--score {score}", "score value to assign (1..10)", Integer) do |v|
        die "invalid score" unless (1..10).include?(v.to_i)
        options[:score] = v.to_i
      end # --score

      op.on('-h', '--help', "show help") do
        die "USAGE: rails dj:process -- [switches] doujin_id file1 file2 ... #{op}\n", 0
      end # --help
    end.parse! ARGV
    
    # first argument is doujin ID
    doujin_id = ARGV.shift.to_i
    die %Q|ERROR: doujin ID [#{doujin_id}] not found| unless dj = Doujin.find_by(id: doujin_id)
    
    # remaining arguments are files to process
    ARGV.each do |dj_fname|
      puts '-'*70
      puts "FILE: #{dj_fname}"
      
      fname = File.expand_path dj_fname
      die %Q|ERROR: file not found| unless File.exist?(fname)
      die %Q|ERROR: file not in "to_sort" folder| unless fname.start_with?(Setting['dir.to_sort'])
      
      hash  = ProcessArchiveDecompressJob.prepare_and_perform fname, perform_when: :now
      die "ERROR: invalid MIME type: not a ZIP file!" if hash == :invalid_zip
      
      dname = File.expand_path File.join(Setting['dir.sorting'], hash)
      info_fname = File.join dname, 'info.yml'
      info  = YAML.load_file info_fname
      puts "HASH: #{hash}"
      
      puts "\n[DST]     [SRC]"
      puts info[:images].map{|i| "#{i[:dst_path]}  #{i[:src_path]}"}
      if info[:files].any?
        puts "--------  --------------------"
        puts info[:files].map{|i| "#{i[:dst_path]}  #{i[:src_path]}"}
      end; puts "\n"
      
      # copy data from source doujin
      info[:file_type    ] = dj.category
      if %w{ author circle }.include?(dj.category)
        info[:file_type       ] = 'doujin'
        info[:doujin_dest_type] = dj.category
      end
      info[:dest_folder  ], info[:subfolder] = dj.file_folder.split('/')
      info[:score        ] = options[:score] if options[:score]
      info[:overwrite    ] = options[:overwrite] if options[:overwrite]
      info[:dest_filename] = options[:dest_filename] if options[:dest_filename]
      info[:dest_filename] = File.basename(fname).sub(/ *\.zip$/i, '.zip') if options[:keep_filename]
      info[:author_ids   ] = dj.author_ids
      info[:circle_ids   ] = dj.circle_ids
      File.open(info_fname, 'w'){|f| f.puts info.to_yaml }
      
      if !options[:overwrite] && File.exist?(Doujin.dest_path_by_process_params(info, full_path: true))
        puts "ERROR: file already exists in collection"
        next
      end
      
      perc_file = File.join(dname, 'finalize.perc')
      unless File.exist?(perc_file)
        FileUtils.touch perc_file
        ProcessArchiveCompressJob.perform_now dname
        
        info = YAML.load_file info_fname
        if info[:finalize_error].blank?
          puts "DjID: #{info[:db_doujin_id]}"
          # remove file on disk and WIP folder
          File.unlink info[:file_path]
          FileUtils.rm_rf dname, secure: true
        else
          puts "ERROR: processing errors [#{info[:finalize_error]}]"
          next
        end
      end
    end # each filename
    
    exit 0 # make sure that the extra arguments won't be interpreted as Rake task
  end # process
end
