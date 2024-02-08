class CoverMatchingJob < ApplicationJob
  # https://github.com/westonplatter/phashion#threshold-for-dupe-detection
  # http://www.mikeperham.com/2010/05/21/detecting-duplicate-images-with-phashion/
  # << Our testing showed that 15 bits is a good value to start with, it detected
  #    all duplicates with a minimum of false positives >>
  MAX_HAMMING_DISTANCE = 13 # = less than ~20% (13/64) different bits
  
  queue_as :search

  # return the image's hash for `perform`
  def self.hash_image_buffer(image_data, hash_only: false)
    fkey  = Digest::MD5.hexdigest image_data
    
    # resize image to a temporary thumbnail
    thumb = Vips::Image.webp_cropped_thumb image_data,
      width:  ProcessArchiveCompressJob::THUMB_WIDTH,
      height: ProcessArchiveCompressJob::THUMB_HEIGHT
    
    # calculate its pHash
    fname = File.join(Setting['dir.sorting'], "#{fkey}.webp").to_s
    File.open(fname, 'wb'){|f| f.write thumb[:image].webpsave_buffer }
    phash = Kernel.suppress_output{ '%016x' % Phashion::Image.new(fname).fingerprint }
    FileUtils.rm_f fname # remove temp image
    
    return phash if hash_only
    
    { phash: phash, landscape: thumb[:landscape],
      image: Base64.encode64(thumb[:image].webpsave_buffer).chomp }
  end # self.hash_image_buffer
  
  def self.hash_image(image_path)
    result = hash_image_buffer File.binread(image_path)
    
    # create metadata + embedded image
    File.atomic_write(File.join(Setting['dir.sorting'], "#{result[:phash]}.yml").to_s) do |f|
      f.puts(result.merge({
        status:     :comparing,
        started_at: Time.now,
      }).to_yaml)
    end
    
    result[:phash]
  end # self.hash_image
  
  # return final results and delete temp file after matching completed
  def self.results(image_hash)
    fname = File.join(Setting['dir.sorting'], "#{image_hash}.yml").to_s
    info  = YAML.unsafe_load_file(fname) rescue nil
    info  = {status: :not_found} unless info.is_a?(Hash)
    
    return info[:status] if info[:status] != :completed
    
    FileUtils.rm_f fname
    info
  end # self.results

  def self.rm_results_file(image_hash)
    FileUtils.rm_f File.join(Setting['dir.sorting'], "#{image_hash}.yml").to_s
  end # self.rm_results_file
  
  def self.find(model, phash, max_distance: MAX_HAMMING_DISTANCE, from_id: 0)
    # https://stackoverflow.com/questions/2281580/is-there-any-way-to-convert-an-integer-3-in-decimal-form-to-its-binary-equival/2310694#2310694
    # https://stackoverflow.com/questions/49601249/string-to-binary-and-back-using-pure-sqlite
    # GENERATE TERMS: puts (0..63).map{|i| "(x>>#{i.to_s.rjust 2}&1)" }.each_slice(5).map{|s| s.join(' + ') }.join(" +\n")
    # NOTE: a XOR b = (a|b)-(a&b) = (~(a&b))&(a|b)
    query = <<~SQL
      SELECT
          id
        , (x    &1) + (x>> 1&1) + (x>> 2&1) + (x>> 3&1) + (x>> 4&1) +
          (x>> 5&1) + (x>> 6&1) + (x>> 7&1) + (x>> 8&1) + (x>> 9&1) +
          (x>>10&1) + (x>>11&1) + (x>>12&1) + (x>>13&1) + (x>>14&1) +
          (x>>15&1) + (x>>16&1) + (x>>17&1) + (x>>18&1) + (x>>19&1) +
          (x>>20&1) + (x>>21&1) + (x>>22&1) + (x>>23&1) + (x>>24&1) +
          (x>>25&1) + (x>>26&1) + (x>>27&1) + (x>>28&1) + (x>>29&1) +
          (x>>30&1) + (x>>31&1) + (x>>32&1) + (x>>33&1) + (x>>34&1) +
          (x>>35&1) + (x>>36&1) + (x>>37&1) + (x>>38&1) + (x>>39&1) +
          (x>>40&1) + (x>>41&1) + (x>>42&1) + (x>>43&1) + (x>>44&1) +
          (x>>45&1) + (x>>46&1) + (x>>47&1) + (x>>48&1) + (x>>49&1) +
          (x>>50&1) + (x>>51&1) + (x>>52&1) + (x>>53&1) + (x>>54&1) +
          (x>>55&1) + (x>>56&1) + (x>>57&1) + (x>>58&1) + (x>>59&1) +
          (x>>60&1) + (x>>61&1) + (x>>62&1) + (x>>63&1) AS hamming_distance
      FROM (
        SELECT id
             , (~(a&b))&(a|b) AS x  -- x = a XOR b
        FROM (
          SELECT id
               , 0x#{phash}   AS a
               , cover_phash  AS b
          FROM #{model.table_name}
          WHERE cover_phash IS NOT NULL
            AND id > #{from_id.to_i}
        )
      )
      WHERE hamming_distance < #{max_distance.to_i}
      ORDER BY hamming_distance
      LIMIT 10
    SQL
    
    model.
      find_by_sql(query).
      inject({}){|h, d| h.merge d.id => ((1 - d.hamming_distance.to_f / 64) * 100).round }
  end # self.find

  # read image data from temp file and do a matching against all saved doujinshi
  # by computing hamming distance between pHashes
  def perform(image_hash, max_distance: MAX_HAMMING_DISTANCE)
    fname = File.join(Setting['dir.sorting'], "#{image_hash}.yml").to_s
    info  = YAML.unsafe_load_file fname
    
    # write results
    info.merge! \
      status:          :completed,
      finished_at:     Time.now,
      results:         CoverMatchingJob.find(Doujin       , image_hash, max_distance: max_distance),
      results_deleted: CoverMatchingJob.find(DeletedDoujin, image_hash, max_distance: max_distance)
    
    File.atomic_write(fname){|f| f.puts info.to_yaml }
  end # perform
end
