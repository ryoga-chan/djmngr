# Pin npm packages by running ./bin/importmap
# https://github.com/rails/importmap-rails
# package search: https://generator.jspm.io

# https://github.com/rails/importmap-rails#local-modules
def pin_all_within(path) = pin_all_from("app/javascript/#{path}", under: path)

pin "application"

pin "libs/app-setup"
pin "libs/app-onload"

pin "libs/jquery"               # https://jquery.com/download/
# https://github.com/rails/jquery-ujs
# https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/rails-ujs.js
pin "libs/jquery-ujs" # @1.2.3

# https://github.com/SortableJS/Sortable
pin "sortablejs" # @1.15.6
pin "libs/sortable-jquery"      # https://github.com/SortableJS/jquery-sortablejs

# https://github.com/ctrl-freaks/freezeframe.js
pin "freezeframe" # @5.0.2
pin "libs/freeze_frame-jquery"

pin_all_within 'components'
pin_all_within 'controllers'
