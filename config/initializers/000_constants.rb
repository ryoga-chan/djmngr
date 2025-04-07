Rails.application.config.proctitle = 'ruby:djmngr'.freeze

# https://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on/19411012#19411012
OS_LINUX   = Gem::Platform.local.os =~ /linux/i
OS_WINDOWS = Gem.win_platform?
DOCKER_VM  = ENV['DOCKER_RUNNING'].present?

DJ_DIR_REPROCESS     = '00_reprocess'.freeze
DJ_DIR_PROCESS_LATER = 'zz_later'.freeze
