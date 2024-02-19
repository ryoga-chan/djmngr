class Setting < ApplicationRecord
  READING_BG_COLORS = %w[ white smoke dark black ]
  PROCESS_IMG_SELECT_MODES = {
    "-  horizontal (top = select, bottom = zoom)"            => "-",
    "|  vertical   (right = select, left = zoom)"            => "|",
    "\\ diagonal   (top-right = select, bottom-left = zoom)" => "\\",
    "/  diagonal   (top-left = zoom, bottom-right = select)" => "/" ,
  }

  serialize :value, coder: JSON

  validate  :validate_record, on: :update

  def validate_record
    return unless value_changed?

    if %w[ dir.to_sort dir.sorting dir.sorted ].include?(key)
      errors.add :base, "#{key}: directory not found" unless File.directory?(value)
    end

    #if %w{ epub_img_width epub_img_height }.include?(key)
    #  errors.add :base, "#{key}: must be >= 640" if value.to_i < 640
    #end

    if key == 'reading_direction'
      errors.add :base, "#{key}: unsupported direction" unless %w[ r2l l2r ].include?(value)
    end

    if key == 'process_img_sel'
      errors.add :base, "#{key}: unsupported mode" unless PROCESS_IMG_SELECT_MODES.values.include?(value)
    end

    if key == 'ext_cmd_env'
      ris = JSON.parse(value) rescue nil
      errors.add :base, "#{key}: invalid JSON" unless ris.is_a?(Hash)
    end

    if key == 'external_link'
      errors.add :base, %Q(#{key}: must be in the format "label|url") unless value =~ /.+\|.+/
    end

    if key == 'epub_devices' && value.to_s.split(',').any?{|i| i.strip !~ /\A[a-zA-Z0-9_]+@[0-9]+x[0-9]+\z/ }
      errors.add :base, %Q(#{key}: must be in the format "device_name@widthxheight, ...")
    end
  end # validate_record

  def self.get(k)= find_by(key: k)
  def self.[] (k)= get(k)&.value
  def self.get_json(k)= JSON.parse(get(k)&.value) rescue nil

  def self.epub_devices
    devices = []

    self[:epub_devices].to_s.split(',').each do |device|
      name, res = device.split('@')
      next unless name && res

      w, h = res.to_s.split('x').map(&:to_i)
      next unless w > 0 && h > 0

      devices << { name: name.strip, width: w, height: h }
    end

    devices
  end # self.epub_devices

  def self.search_engines
    @@search_engines ||= self.
      where("key LIKE 'search_engine.%'").
      where.not(value: '').
      order(:key).
      map{|s|
        next if s.value.start_with?('-')
        s.value.to_s.split('|')
      }.compact
  end # self.search_engines
end
