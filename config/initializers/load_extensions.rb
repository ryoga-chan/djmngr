# load all core extensions
lib_folder = File.expand_path File.join(Rails.root, 'lib')
files_glob = File.join lib_folder, 'core_ext', '**', '*.rb'
exclude_begin = lib_folder.size + 1
exclude_end   = -4

Dir[files_glob].sort.each do |l|
  require l[exclude_begin..exclude_end]
end
