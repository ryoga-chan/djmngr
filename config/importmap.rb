# Pin npm packages by running ./bin/importmap
# https://github.com/rails/importmap-rails
# package search: https://generator.jspm.io

# https://github.com/rails/importmap-rails#local-modules
def pin_all_within(path) = pin_all_from("app/javascript/#{path}", under: path)

pin "application"

pin "libs/app"

pin "libs/jquery"               # https://jquery.com/download/
# https://github.com/rails/jquery-ujs
# https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/rails-ujs.js
pin "jquery-ujs" # @1.2.3

# https://github.com/SortableJS/Sortable
pin "sortablejs" # @1.15.6
pin "libs/sortable-jquery"      # https://github.com/SortableJS/jquery-sortablejs

# https://github.com/ctrl-freaks/freezeframe.js
pin "freezeframe" # @5.0.2
pin "libs/freeze_frame-jquery"

# TODO: see alternatives
#   - https://stackoverflow.com/questions/21444253/jquery-swipe-without-jquery-mobile-library/21444454#21444454
#   - https://www.w3schools.com/jsref/event_touchstart.asp
pin "libs/hammer"               # https://github.com/hammerjs/hammer.js (swipe events)
pin "libs/hammer-jquery"        # https://github.com/hammerjs/jquery.hammer.js

pin_all_within 'components'
pin_all_within 'controllers'
