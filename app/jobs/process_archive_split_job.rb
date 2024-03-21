class ProcessArchiveSplitJob < ApplicationJob
  queue_as :tools

  def perform(src_dir, paths)
    return 0 if paths&.size.to_i == 0

    info = YAML.unsafe_load_file(File.join src_dir, 'info.yml')

    sets, set, path = [], [], paths.shift
    info[:images].each do |image|
      if image[:src_path] == path
        sets << set if set.any?
        set   = [image]
        path  = paths.shift
      else
        set  << image
      end
    end # each image
    sets << set if set.any?

    # create new working folders
    info[:images] = []
    sets.each_with_index do |set, set_idx|
      info_new = info.dup
      num = '%03d' % (set_idx + 1)
      dir = "#{src_dir}_#{num}" # new base folder
      
      # create subfolders
      %w( contents cover thumbs ).each{|d| FileUtils.mkdir_p File.join(dir, d) }

      set.each do |image|
        # copy image
        src_path = File.join src_dir, 'contents', image[:src_path]
        dst_path = File.join dir    , 'contents', (image[:src_path].tr!(File::SEPARATOR, '_') || image[:src_path])
        FileUtils.cp_hard src_path, dst_path, force: true
        # copy thumb
        src_path = File.join src_dir, 'thumbs', image[:thumb_path]
        dst_path = File.join dir    , 'thumbs', image[:thumb_path]
        FileUtils.cp_hard src_path, dst_path, force: true
      end # each image
      
      # info
      info_new[:images           ]  = set
      info_new[:working_dir      ]  = File.basename dir
      info_new[:prepared_at      ]  = Time.now
      info_new[:cover_hash       ]  = nil
      info_new[:dest_title       ] += " #{num}" if info_new[:dest_title       ].present?
      info_new[:dest_title_romaji] += " #{num}" if info_new[:dest_title_romaji].present?
      info_new[:dest_title_eng   ] += " #{num}" if info_new[:dest_title_eng   ].present?
      info_new[:dest_filename    ]  = info[:dest_filename].sub(/ *\.zip/i, " #{num}.zip")
      info_new[:file_path        ] += ".#{num}"
      info_new[:relative_path    ] += ".#{num}"

      # autogenerate portrait cover for landascape first image
      ProcessArchiveDecompressJob.crop_landscape_cover dir, info_new
      
      File.atomic_write(File.join(dir, 'info.yml')){|f| f.puts info_new.to_yaml }
    end # each set

    sets.size
  end # perform
end
