class Setting < ApplicationRecord
  serialize :value, JSON
  
  def self.get(k)= find_by(key: k)
  def self.[] (k)= get(k)&.value
end
