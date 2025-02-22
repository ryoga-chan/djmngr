module CoreExt::Zip::Utils
  def image_entries(sort: false)
    list = entries.select{|e| e.file? && e.name.is_image_filename? }
    return list unless sort
    list.sort{|a, b| a.name.to_a_sortable_by_numbers <=> b.name.to_a_sortable_by_numbers }
  end # image_entries
end

Zip::File.send :include, CoreExt::Zip::Utils
