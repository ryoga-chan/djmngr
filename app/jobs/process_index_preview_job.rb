class ProcessIndexPreviewJob < ProcessIndexRefreshJob
  def self.description = :'generating previews'
  
  def self.rm_previews
    pattern = Rails.root.join('public', ProcessableDoujin::THUMB_FOLDER, '*.webp').to_s
    Dir[pattern].each{|f| FileUtils.rm_f f }
  end # self.rm_previews
  
  def perform(id: nil, order: nil, page: nil)
    page = 1 if page.to_i <= 0
    
    rel = self.class.entries(order: order)
    rel = rel.where(id: id) if id
    
    records = []
    if order.to_s.starts_with?('group')
      records  = rel.page(p.to_i).per(ProcessController::GROUP_EPP).to_a
      # generate preview for child records
      records += records.inject([]){|a,r| a.concat r.processable_doujin_childs }
    else
      # generate preview for two pages
      records  = rel.page(p.to_i).per(Setting[:process_epp].to_i).to_a
      records += rel.page(p.to_i+1).per(Setting[:process_epp].to_i).to_a
    end
    
    records.each_with_index do |processable_doujin, i|
      self.class.progress_update step: i+1, steps: records.size
      processable_doujin.generate_preview
    end
  end # perform
end
