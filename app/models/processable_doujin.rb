class ProcessableDoujin < ApplicationRecord
  THUMB_WIDTH  = 320
  THUMB_HEIGHT = 640
  THUMBS_CHUNK = 3
  THUMB_FOLDER = 'samples'

  has_many :processable_doujin_dupes_parents, foreign_key: :pd_child_id , class_name: 'ProcessableDoujinDupe', dependent: :delete_all
  has_many :processable_doujin_dupes_childs , foreign_key: :pd_parent_id, class_name: 'ProcessableDoujinDupe', dependent: :delete_all
    has_many :processable_doujin_parents, through: :processable_doujin_dupes_parents
    has_many :processable_doujin_childs , through: :processable_doujin_dupes_childs
    has_many :doujinshi                 , through: :processable_doujin_dupes_childs

  after_destroy :delete_files

  def self.search(terms)
    fname_info    = terms.to_s.strip    .parse_doujin_filename
    tokens_orig   = terms.to_s          .tokenize_doujin_filename.join '%'
    tokens_kakasi = terms.to_s.to_romaji.tokenize_doujin_filename.join '%'

    return self.none if tokens_orig.size < 3

    tn = ProcessableDoujin.table_name

    # search all terms on the original filename
    rel_conditions = [
      ProcessableDoujin.where("#{tn}.name            LIKE ?", "%#{tokens_orig  }%"),
      ProcessableDoujin.where("#{tn}.name_kakasi     LIKE ?", "%#{tokens_kakasi}%"),
    ]

    # search only filename terms
    if fname_info[:fname].present?
      tokens_orig   = fname_info[:fname].to_s          .tokenize_doujin_filename.join '%'
      tokens_kakasi = fname_info[:fname].to_s.to_romaji.tokenize_doujin_filename.join '%'
      rel_conditions += [
        ProcessableDoujin.where("#{tn}.name            LIKE ?", "%#{tokens_orig  }%"),
        ProcessableDoujin.where("#{tn}.name_kakasi     LIKE ?", "%#{tokens_kakasi}%"),
      ]
    end

    # build query with all conditions in OR
    rel = rel_conditions.shift
    rel_conditions.each{|cond| rel = rel.or cond }

    rel.order(:name_kakasi)
  end # self.search

  def file_path(full: false) = full ? File.join(Setting['dir.to_sort'], name) : name

  # append a hash to the url to ignore browser cache when the file name changes
  def name_hash = @cache_name_hash ||= Digest::MD5.hexdigest("djmngr|#{name}|#{name.size}")
  def thumb_url(mobile: false)  = "/#{THUMB_FOLDER}/#{'%010d' % id}-#{mobile ? :m : :d}.webp?h=#{name_hash}"

  def thumb_path(mobile: false) = Rails.root.join('public', THUMB_FOLDER, "#{'%010d' % id}-#{mobile ? :m : :d}.webp").to_s

  def delete_files
    File.unlink(thumb_path(mobile: true )) if File.exist?(thumb_path(mobile: true ))
    File.unlink(thumb_path(mobile: false)) if File.exist?(thumb_path(mobile: false))
  end # delete_files

  def process_later
    ProcessableDoujin.transaction do
      src_file = File.expand_path File.join(Setting['dir.to_sort'], name)
      dst_file = File.expand_path File.join(Setting['dir.to_sort'], DJ_DIR_PROCESS_LATER, name)

      update! name:        File.join(DJ_DIR_PROCESS_LATER, "#{name}"),
              name_kakasi: File.join(DJ_DIR_PROCESS_LATER, "#{name_kakasi}")

      # create dest folder and move file
      FileUtils.mkdir_p File.dirname(dst_file)
      FileUtils.mv src_file, dst_file, force: true
    end
  end # process_later

  # extract cover from zip file and generate its phash
  def cover_fingerprint
    fname = file_path full: true
    return unless File.exist?(fname)

    phash = nil

    Zip::File.open(fname) do |zip|
      zip_images = zip.image_entries(sort: true)

      if zip_images.any?
        phash = CoverMatchingJob.hash_image_buffer zip_images.first.get_input_stream.read, hash_only: true
        @images = zip_images.size
      end
    end

    phash
  end # cover_fingerprint

  def cover_fingerprint!
    raise :record_not_persisted unless persisted?
    fp = cover_fingerprint
    self.class.connection.execute \
      %Q(UPDATE #{self.class.table_name} SET cover_phash = 0x#{fp} WHERE id = #{id})
    update images: @images
    fp
  end # cover_fingerprint!

  def generate_preview
    return if File.exist?(thumb_path)

    fname = file_path full: true
    return unless File.exist?(fname)

    Zip::File.open(fname) do |zip|
      zip_images = zip.image_entries(sort: true)
      update images: zip_images.size

      thumb_entries = zip_images.pages_preview(chunk_size: THUMBS_CHUNK)

      images = thumb_entries.map{|e|
        i = Vips::Image.webp_cropped_thumb(
          e.get_input_stream.read,
          width:   THUMB_WIDTH,
          height:  THUMB_HEIGHT,
          padding: false
        )[:image]

        # https://github.com/libvips/pyvips/issues/202
        # https://github.com/libvips/libvips/issues/1525
        i = i.colourspace('srgb') if i.bands  < 3
        i = i.bandjoin(255)       if i.bands == 3

        i
      }.compact

      # display missing image if no images are found
      images << self.class.img_not_found if images.empty?

      # use transparent images for the remaining thumbs
      num_fill = (images.size.to_f / 3).ceil * 3
      images += (images.size ... num_fill).map{ self.class.img_transparent }

      # https://github.com/libvips/ruby-vips/blob/master/lib/vips/methods.rb#L362
      # 1. create a long thumbnail for desktop
      collage = Vips::Image.arrayjoin images, background: 0
      collage.write_to_file thumb_path(mobile: false)
      # 2. create a portrait thumbnail for mobile
      collage = Vips::Image.arrayjoin images, background: 0, across: THUMBS_CHUNK
      collage.write_to_file thumb_path(mobile: true)
    end
  end # generate_preview

  def self.img_not_found
    @@img_not_found ||= Vips::Image.webp_cropped_thumb(
      File.binread(Rails.root.join('public', 'not-found.png').to_s),
      width:   THUMB_WIDTH,
      height:  THUMB_HEIGHT,
      padding: false
    )[:image]
  end # self.img_not_found

  def self.img_transparent
    # https://github.com/libvips/pyvips/issues/326
    @@img_trasparent ||= Vips::Image.
      black(2, 2). # with x height in pixels
      copy(interpretation: "srgb").
      new_from_image([0, 0, 0, 0])
  end # self.img_transparent
  
  def parse_name = @cache_parse_name ||= name.parse_doujin_filename
  
  def group_sort_flags
    return @cache_group_sort_flags if @cache_group_sort_flags
    @cache_group_sort_flags = '11111' # unc, eng, jpn, kor, chi
    @cache_group_sort_flags[0] = '0' if parse_name[:properties].include?('unc')
    @cache_group_sort_flags[1] = '0' if parse_name[:language] == 'eng'
    @cache_group_sort_flags[2] = '0' if parse_name[:language] == 'jpn'
    @cache_group_sort_flags[3] = '0' if parse_name[:language] == 'kor'
    @cache_group_sort_flags[4] = '0' if parse_name[:language] == 'chi'
    @cache_group_sort_flags
  end # group_sort_flags
end
