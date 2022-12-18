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
      end # --name
      
      op.on("-t title", "--title {titlename}", "use a custom title name", String) do |v|
        die "empty titlename" if v.blank?
        options[:dest_title] = v
      end # --title
      
      op.on("-k", "--keep-filename", "keep filename"){ options[:keep_filename] = true }
      
      op.on("-s score", "--score {score}", "score value to assign (1..10)", Integer) do |v|
        die "invalid score" unless (1..10).include?(v.to_i)
        options[:score] = v.to_i
      end # --score
      
      op.on("-c", "--color", "is colorized" ){ options[:col] = true }
      op.on("-g", "--game" , "is game HCG"  ){ options[:hcg] = true }
      op.on("-u", "--unc"  , "is uncensored"){ options[:unc] = true }

      op.on('-h', '--help', "show help") do
        die "USAGE: rails dj:process -- [switches] doujin_id file1 file2 ... #{op}\n", 0
      end # --help
    end.parse! ARGV
    
    # first argument is doujin ID
    doujin_id = ARGV.shift.to_i
    die %Q|ERROR: doujin ID [#{doujin_id}] not found| unless dj = Doujin.find_by(id: doujin_id)
    
    ProcessBatchJob.perform_now doujin_id, ARGV, options
    
    exit 0 # make sure that the extra arguments won't be interpreted as Rake task
  end # process
end
