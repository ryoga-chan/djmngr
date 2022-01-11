# https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html
# https://stackoverflow.com/questions/2513383/access-current-user-in-model#2513456
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
