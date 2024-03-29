module CoreExt::Zip::Utils
  def image_entries(sort: false)
    list = entries.select{|e| e.file? && e.name.is_image_filename? }
    sort ? list.sort_by_method(:name) : list
  end # image_entries
end

Zip::File.send :include, CoreExt::Zip::Utils
