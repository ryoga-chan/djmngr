require 'optparse'

# bin/rails dj:process -- ...
namespace :dj do
  desc 'process a doujin'
  task process: :environment do |args|
    options = {}
    
    OptionParser.new do |op|
      op.banner = '' # Set a banner, displayed at the top of the help screen.
      
      #op.on('-u USER', '--user USER', String, "username"){|v| options[:user] = v }
      #op.on('-p PORT', '--port PORT', Integer, "tcp port"){|v| options[:port] = v }
      #op.on('-t', '--tunnels', "show opened tunnels") \
      #  { system "sudo lsof -i -n | egrep ssh\\|COMMAND"; exit 0 }
      #op.on('-l', '--list', "show vm names") { puts VMS.keys; exit 0 }
      
      op.on("-u", "--user {username}","User's email address", String) do |user|
        options[:user] = user
      end
      
      op.on("-p", "--pass {password}","User's password", String) do |pass|
        options[:pass] = pass
      end

      op.on('-h', '--help', "show help"){
        puts "USAGE: rails dj:process -- [switches]#{op}\n"
        exit 1
      }# --help
    end.parse! ARGV[1..-1]
    
    puts options.inspect
    
    exit 0 # make sure that the extra arguments won't be interpreted as Rake task
  end # process
end
