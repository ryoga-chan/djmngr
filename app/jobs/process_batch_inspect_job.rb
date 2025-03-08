class ProcessBatchInspectJob < ApplicationJob
  queue_as :tools

  def perform(hash)
    info_path = ProcessBatchJob.info_path(hash)
    info = YAML.unsafe_load_file info_path

    # TODO: rewrite using a single hash with multiple properties
    info[:thumbs] = {}
    info[:titles] = {}
    info[:sizes ] = {}
    info[:files].keys.each do |name|
      info[:titles][name] = File.basename(name).sub(/ *\.zip$/i, '')

      file_path = File.join Setting['dir.to_sort'], name
      info[:sizes][name] = File.size file_path

      Zip::File.open(file_path) do |zip|
        image_entries = zip.image_entries(sort: true)

        info[:files][name] = image_entries.map &:name

        if cover = image_entries.first # extract cover image
          info[:thumbs][name] = CoverMatchingJob.hash_image_buffer cover.get_input_stream.read
        end
      end

      File.atomic_write(info_path){|f| f.puts info.to_yaml }
    end

    # sort and group filenames by hamming distance
    groups = {}
    info[:titles].keys.sort.map{|k, v| k}.each do |f|
      matching_found = false

      groups.keys.each do |g|
        match_found = CoverMatchingJob.similarity \
          info[:thumbs][f][:phash ], info[:thumbs][g][:phash ],
          info[:thumbs][f][:idhash], info[:thumbs][g][:idhash]

        if match_found
          groups[g] << f
          matching_found = true
          break
        end
      end

      groups[f] = [f] unless matching_found
    end
    info[:filenames] = groups.values.flatten

    # write info to disk
    info[:prepared_at] = Time.now
    File.atomic_write(info_path){|f| f.puts info.to_yaml }
  end # perform
end
