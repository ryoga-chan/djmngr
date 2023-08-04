# https://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on/19411012#19411012
OS_LINUX   = Gem::Platform.local.os =~ /linux/i
OS_WINDOWS = Gem.win_platform?

RE_IMAGE_EXT = /\.(jpe*g|gif|png)$/i

# default image manipulation output quality
IMG_QUALITY_THUMB  = 70
IMG_QUALITY_RESIZE = 80

DJ_DIR_REPROCESS     = '00_reprocess'.freeze
DJ_DIR_PROCESS_LATER = 'zz_later'.freeze
