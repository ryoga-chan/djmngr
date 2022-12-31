# https://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on/19411012#19411012
OS_LINUX   = Gem::Platform.local.os =~ /linux/i
OS_WINDOWS = Gem.win_platform?

RE_IMAGE_EXT = /\.(jpe*g|gif|png)$/i
