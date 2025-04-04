class ProcessIndexGroupJob < ProcessIndexRefreshJob
  DEVEL_LIMIT = 100

  def self.description = :'grouping by cover similarity'

  def self.rm_entry(id) = ProcessableDoujinDupe.find_by(id: id.to_i)&.destroy

  # params:
  #   ids   = ProcessableDoujin IDs to (re)process
  #   page  = cover image's page number
  def perform(*args)
    opts = args.first.is_a?(Hash) ? args.first : {}
    page = opts[:page] || 1

    # rehash specific entries
    if opts[:ids]
      ProcessableDoujinDupe.where(pd_parent_id: opts[:ids]).delete_all
      ProcessableDoujinDupe.where(pd_child_id:  opts[:ids]).delete_all
    end

    # generate covers fingerprints
    rel = opts[:ids] \
      ? ProcessableDoujin.where(id: opts[:ids])   # rehash specific entries
      : ProcessableDoujin.where(cover_phash: nil) # hash new entries
    num_entries = rel.count
    print_info_freq = [num_entries / 100 + 1, 10].max
    rel.find_each.with_index do |pd, i|
      break if Rails.env.development? && i >= DEVEL_LIMIT

      ris = self.class.progress_update(step: (i+1), steps: num_entries, msg: 'fingerprinting covers')
      Rails.logger.info(ris) if i % print_info_freq == 0

      pd.cover_fingerprint!(page: page) rescue Rails.logger.error("ERROR: ID #{pd.id} => #{$!}")
    end # each row

    # calculate covers similarity
    if opts[:ids]   # consider all entries
      last_id = 0
    else            # consider new entries only
      last_id = ProcessableDoujinDupe.maximum(:pd_parent_id)
      rel = ProcessableDoujin.where.not(cover_phash: nil).where("id >= ?", last_id.to_i)
    end
    num_entries = rel.count
    print_info_freq = [num_entries / 100 + 1, 10].max
    rel.select("id, cover_phash, cover_sdhash").find_each.with_index do |pd, i|
      break if Rails.env.development? && i >= DEVEL_LIMIT

      ris = self.class.progress_update(step: (i+1), steps: num_entries, msg: 'comparing covers')
      Rails.logger.info(ris) if i % print_info_freq == 0

      ProcessableDoujin.transaction do
        from_id = last_id \
          ? 0       # table already contains records: compare with all entries
          : pd.id   # table was empty: optimize matching, compare only subsequent IDs
        CoverMatchingJob.find(ProcessableDoujin, pd.cover_phash, pd.cover_sdhash, from_id: from_id).each do |id, perc|
          next if pd.id == id
          ids = [pd.id, id].sort
          pdd = ProcessableDoujinDupe.find_or_initialize_by(pd_parent_id: ids[0], pd_child_id: ids[1])
          pdd.update likeness: perc
        end # each dupe

        CoverMatchingJob.find(Doujin, pd.cover_phash, pd.cover_sdhash).each do |id, perc|
          pdd = ProcessableDoujinDupe.find_or_initialize_by(pd_parent_id: pd.id, doujin_id: id)
          pdd.update likeness: perc
        end # each dupe
      end # transaction
    end # each row
  end # perform
end
