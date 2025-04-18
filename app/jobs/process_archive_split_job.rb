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
      %w[ contents cover thumbs ].each{|d| FileUtils.mkdir_p File.join(dir, d) }

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

      # update info
      info_new[:dummy            ] = true
      info_new[:images           ] = set
      info_new[:working_dir      ] = File.basename dir
      info_new[:prepared_at      ] = Time.now
      info_new[:cover_hash       ] = nil
      # place the index number before trailing parenthesis
      re_expr, re_repl = /(.+?)( \(.+\))*(\.zip)*$/i, "\\1 #{num}\\2\\3"
      info_new[:dest_title       ] = info[:dest_title       ].sub(re_expr, re_repl) if info[:dest_title       ].present?
      info_new[:dest_title_romaji] = info[:dest_title_romaji].sub(re_expr, re_repl) if info[:dest_title_romaji].present?
      info_new[:dest_title_eng   ] = info[:dest_title_eng   ].sub(re_expr, re_repl) if info[:dest_title_eng   ].present?
      info_new[:dest_filename    ] = info[:dest_filename    ].sub(re_expr, re_repl)
      info_new[:file_path        ] = [info[:file_path    ][0].sub(re_expr, re_repl)]
      info_new[:relative_path    ] = [info[:relative_path][0].sub(re_expr, re_repl)]

      # autogenerate portrait cover for landascape first image
      ProcessArchiveDecompressJob.crop_landscape_cover dir, info_new

      File.atomic_write(File.join(dir, 'info.yml')){|f| f.puts info_new.to_yaml }
    end # each set

    sets.size
  end # perform
end
