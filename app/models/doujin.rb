class Doujin < ApplicationRecord
  has_and_belongs_to_many :authors, before_add: -> (d, a) {
    return unless d.authors.where(id: a.id).exists? # ensure uniqueness
    d.errors.add :base, "author already associated [#{a.id}: #{a.name}]"
    throw :abort
  }
  has_and_belongs_to_many :circles, before_add: -> (d, c) {
    return unless d.circles.where(id: c.id).exists? # ensure uniqueness
    d.errors.add :base, "circle already associated [#{c.id}: #{c.name}]"
    throw :abort
  }
  
  after_destroy :delete_thumbnail
  
  def self.dest_path_by_process_params(info, full_path: false)
    path = full_path ? [Setting['dir.sorted']] : []
    path << (info[:file_type] == 'doujin' ? info[:doujin_dest_type] : info[:file_type]).to_s
    path << info[:dest_folder  ].to_s.gsub(/[\/\\]/, '_')
    path << info[:subfolder    ].to_s.gsub(/[\/\\]/, '_')
    path << info[:dest_filename].to_s.gsub(/[\/\\]/, '_')
    File.join '/', *path
  end # self.dest_path_by_process_params
  
  # find doujin by destination folder
  def self.find_by_process_params(info)
    cat  = (info[:file_type] == 'doujin' ? info[:doujin_dest_type] : info[:file_type]).to_s
    fold = File.join *[info[:dest_folder], info[:subfolder]].select(&:present?).map{|i| i.to_s.gsub(/[\/\\]/, '_') }
    fold = '.' if fold.blank?
    name = info[:dest_filename].to_s.gsub(/[\/\\]/, '_')
    self.find_by category: cat, file_folder: fold, file_name: name
  end # self.find_by_process_params
  
  def file_path
    tmp_folder = self.file_folder == '.' ? '' : self.file_folder
    File.join self.category, tmp_folder, self.file_name
  end # file_path
  
  def to_label
    self.name_romaji.present? ? self.name_romaji : self.name_kakasi
  end # to_label
  
  
  private # ____________________________________________________________________
  
  
  def delete_thumbnail
    thumb_path = File.join Rails.root, 'public', 'thumbs', "#{self.id}.webp"
    File.unlink(thumb_path) if File.exist?(thumb_path)
  end # delete_thumbnail
end
