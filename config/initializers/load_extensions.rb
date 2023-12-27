# OBSOLETE: superseded by /config/application.rb - config.autoload_lib
#   https://www.shakacode.com/blog/rails-7-1-introduces-config-autoload_lib/
#   https://github.com/rails/rails/pull/49032
## load all core extensions
#lib_folder = File.expand_path File.join(Rails.root, 'lib')
#files_glob = File.join lib_folder, 'core_ext', '**', '*.rb'
#
#Dir[files_glob].sort.each do |l|
#  require Pathname.new(l).relative_path_from(lib_folder).to_s
#end
