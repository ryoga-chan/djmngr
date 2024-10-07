class ProcessIndexGroupJob < ProcessIndexRefreshJob
  DEVEL_LIMIT = 100

  def self.description = :'grouping by cover similarity'

  def self.rm_entry(id) = ProcessableDoujinDupe.find_by(id: id.to_i)&.destroy

  def perform(*args)
    # generate covers fingerprints
    rel = ProcessableDoujin.where(cover_phash: nil)
    num_entries = rel.count
    print_info_freq = [num_entries / 100 + 1, 10].max
    rel.find_each.with_index do |pd, i|
      break if Rails.env.development? && i >= DEVEL_LIMIT

      ris = self.class.progress_update(step: (i+1), steps: num_entries, msg: 'fingerprinting covers')
      Rails.logger.info(ris) if i % print_info_freq == 0

      pd.cover_fingerprint! rescue Rails.logger.error("ERROR: ID #{pd.id} => #{$!}")
    end # each row

    # calculate covers similarity
    last_id = ProcessableDoujinDupe.maximum(:pd_parent_id)
    rel = ProcessableDoujin.where.not(cover_phash: nil).where("id >= ?", last_id.to_i)
    num_entries = rel.count
    print_info_freq = [num_entries / 100 + 1, 10].max
    rel.select("id, PRINTF('%016x', cover_phash) AS cover_phash_hex").find_each.with_index do |pd, i|
      break if Rails.env.development? && i >= DEVEL_LIMIT

      ris = self.class.progress_update(step: (i+1), steps: num_entries, msg: 'comparing covers')
      Rails.logger.info(ris) if i % print_info_freq == 0

      ProcessableDoujin.transaction do
        CoverMatchingJob.find(ProcessableDoujin, pd.cover_phash_hex, from_id: (last_id ? 0 : pd.id)).each do |id, perc|
          next if pd.id == id
          ids = [pd.id, id].sort
          pdd = ProcessableDoujinDupe.find_or_initialize_by(pd_parent_id: ids[0], pd_child_id: ids[1])
          pdd.update likeness: perc
        end # each dupe

        CoverMatchingJob.find(Doujin, pd.cover_phash_hex).each do |id, perc|
          pdd = ProcessableDoujinDupe.find_or_initialize_by(pd_parent_id: pd.id, doujin_id: id)
          pdd.update likeness: perc
        end # each dupe
      end # transaction
    end # each row
  end # perform
end
