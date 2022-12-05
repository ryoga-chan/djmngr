class Setting < ApplicationRecord
  READING_BG_COLORS = %w{ white smoke dark black }

  serialize :value, JSON
  
  validate  :validate_record, on: :update
  
  def validate_record
    return unless value_changed?
    
    if %w{ dir.to_sort dir.sorting dir.sorted }.include?(key)
      errors.add :base, "#{key}: directory not found" unless File.directory?(value)
    end
    
    if %w{ epub_img_width epub_img_height }.include?(key)
      errors.add :base, "#{key}: must be >= 640" if value.to_i < 640
    end
    
    if key == 'reading_direction'
      errors.add :base, "#{key}: unsupported direction" unless %w{ r2l l2r }.include?(value)
    end
    
    if key == 'ext_cmd_env'
      ris = JSON.parse(value) rescue nil
      errors.add :base, "#{key}: invalid JSON" unless ris.is_a?(Hash)
    end
    
    if key == 'external_link'
      errors.add :base, %Q[#{key}: must be in the format "label|url"] unless value =~ /.+\|.+/
    end
  end # validate_record
  
  def self.get(k)= find_by(key: k)
  def self.[] (k)= get(k)&.value
  def self.get_json(k)= JSON.parse(get(k)&.value) rescue nil
end
