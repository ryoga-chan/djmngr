class ProcessIndexRefreshJob < ApplicationJob
  queue_as :tools

  ORDER = {
    '📄 name'  => :name,
    '📃 xlate' => :kakasi,
    '🕛 time'  => :time,
    '🧰 size'  => :size,
    '📔 cover' => :group,
  }

  around_perform do |job, block|
    self.class.lock_file!
    block.call
    self.class.cleanup_files
  end # around_perform

  def self.cleanup_files
    rm_lock_file
    rm_progress_file
  end # self.cleanup_files

  def self.description      = :'indexing files'

  def self.lock_file        = File.join(Setting['dir.to_sort'], 'indexing.lock').to_s
  def self.lock_file!       = FileUtils.touch(lock_file)
  def self.lock_file?       = File.exist?(lock_file)
  def self.rm_lock_file     = FileUtils.rm_f(lock_file)

  def self.progress_file    = File.join(Setting['dir.sorting'], 'process-job.progress').to_s
  def self.rm_progress_file = FileUtils.rm_f(progress_file)
  def self.progress = File.read(progress_file) rescue :"starting job..."
  def self.progress_update(step:, steps:, msg: nil)
    text = "#{msg || description} | #{'%0.2f' % (step/steps.to_f*100)}% (#{step}/#{steps}) | #{Time.now.strftime '%F %T'}"
    File.atomic_write(progress_file){|f| f.write text }
    text
  end # self.progress_update

  def self.entries(order: 'name', term: nil)
    m = ProcessableDoujin

    m_group = m.
      eager_load(:processable_doujin_dupes_childs, :processable_doujin_childs, :doujinshi).
      where(id: ProcessableDoujinDupe.distinct.select(:pd_parent_id)).
      where.not(id: ProcessableDoujinDupe.where.not(pd_child_id: nil).distinct.select(:pd_child_id))

    rel = case order
      when 'name'    .freeze then m.order :name
      when 'kakasi'  .freeze then m.order Arel.sql("replace(name_kakasi, ' ', '')")
      when 'time'    .freeze then m.order mtime: :desc
      when 'size'    .freeze then m.order size: :desc
      when 'group'   .freeze then m_group.order(:name)
      else                        m.order :name
    end

    rel = rel.search(term) if term.present?

    rel
  end # self.entries

  def self.rm_entry(path_or_id, track: false, rm_zip: false, merged: false, doujin_id: nil)
    # dummy empty zip files created in /tmp
    if path_or_id.is_a?(String) && File.exist?(path_or_id) &&
       File.expand_path(path_or_id).start_with?(Rails.root.join('tmp').to_s)
       FileUtils.rm_f(path_or_id)
       return true
    end

    pd = ProcessableDoujin.find_by(id: path_or_id.to_i) ||
         ProcessableDoujin.find_by(name: path_or_id)
    return false unless pd

    zip_path = pd.file_path full: true

    if File.exist?(zip_path)
      if track
        dd = DeletedDoujin.new

        # count images and other files
        Zip::File.open(zip_path) do |zip|
          entries = zip.split_entries(sort: true)

          dd.num_images = entries[:images].size
          dd.num_files  = entries[:files ].size

          # generate phash for the first image file
          if cover = entries[:images].first
            h = CoverMatchingJob.hash_image_buffer(cover.get_input_stream.read, hash_only: true)
            dd.cover_phash  = h[:phash]
            dd.cover_sdhash = h[:sdhash]
          end
        end

        # track deletion
        name = pd.name.tr File::SEPARATOR, ' '
        dd.update! name:        name,
                   name_kakasi: name.to_romaji,
                   size:        File.size(zip_path),
                   merged:      merged,
                   doujin_id:   doujin_id
      end # if track

      # remove file from disk
      File.unlink zip_path if rm_zip
    end

    pd.destroy
  end # self.rm_entry

  def self.add_entry(full_path)
    fs = File.stat full_path
    rel_name = Pathname.new(full_path).relative_path_from(Setting['dir.to_sort']).to_s
    # ensure no dupes are created
    ProcessableDoujin.
      find_or_initialize_by(name: rel_name).
      update!(name_kakasi: rel_name.to_romaji, size: fs.size, mtime: fs.mtime)
  end # self.add_entry

  def perform(*args)
    ProcessableDoujin.transaction do
      unless ProcessableDoujin.exists?
        ProcessIndexPreviewJob.rm_previews
        ProcessableDoujin     .truncate_and_restart_sequence
        ProcessableDoujinDupe .truncate_and_restart_sequence
      end

      self.class.progress_update step: 1, steps: 3, msg: 'listing db files'
      files_db   = ProcessableDoujin.order(:name).pluck :name

      self.class.progress_update step: 2, steps: 3, msg: 'listing disk files'
      files_glob = File.join Setting['dir.to_sort'], '**', '*.zip'
      files      = Dir[files_glob].sort

      # add new files
      files.each_with_index do |f, i|
        self.class.progress_update step: i+1, steps: files.size

        name = Pathname.new(f).relative_path_from(Setting['dir.to_sort']).to_s
        self.class.add_entry(f) unless files_db.delete(name)
      end

      # remove vanished files
      files_db.each_with_index do |name, i|
        self.class.progress_update step: i+1, steps: files_db.size, msg: :'deindexing vanished files'
        ProcessableDoujin.find_by(name: name)&.destroy
      end
    end # transaction
  end # perform
end
