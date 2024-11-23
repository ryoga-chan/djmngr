module ArchiveUtils
  def self.check_filename_collisions(info_hash)
    info_hash[:files_collision ] = info_hash[:files ].group_by{|i| i[:dst_path] }.map{|k, v| k if v.many? }.compact.sort
    info_hash[:images_collision] = info_hash[:images].group_by{|i| i[:dst_path] }.map{|k, v| k if v.many? }.compact.sort
    info_hash
  end # self.check_filename_collisions
end # ArchiveUtils
