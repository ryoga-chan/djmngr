# app config values:
#   SET: Rails.application.config.xxx = 123
#   GET: Rails.configuration.xxx

# https://stackoverflow.com/questions/13506690/how-to-determine-if-rails-is-running-from-cli-console-or-as-server
# https://stackoverflow.com/questions/26095275/how-to-detect-that-you-rails-app-is-running-from-a-rails-runner
APP_MODE = case
  when defined?(Rails::Server)     then :server
  when defined?(Rails::Console)    then :console
  when defined?(Rails::Generators) then :generator
  when defined?(Rake)              then :task
  else                                  :runner # most likely
end

# https://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on/19411012#19411012
OS_LINUX   = Gem::Platform.local.os =~ /linux/i
OS_WINDOWS = Gem.win_platform?
DOCKER_VM  = ENV['DOCKER_RUNNING'].present?

DJ_DIR_REPROCESS     = '00_reprocess'.freeze
DJ_DIR_PROCESS_LATER = 'zz_later'.freeze
