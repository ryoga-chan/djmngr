# load all core extensions
lib_folder = File.join(Rails.root, 'lib').to_s

Dir.chdir(lib_folder) do
  files_glob = File.join('core_ext', '**', '*.rb')
  Dir[files_glob].sort.each{|l| require l[0..-4] }
end
