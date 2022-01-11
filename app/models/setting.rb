class Setting < ApplicationRecord
  serialize :value, JSON
  
  def self.get(k)= self.find_by(key: k)
  def self.[] (k)= self.get(k)&.value
end
