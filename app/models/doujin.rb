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
  
  before_validation :sanitize_fields
  after_destroy :delete_files
  
  include JapaneseLabels
  
  def sanitize_fields
    self.scored_at = Time.now if score_changed?
  end # sanitize_fields
  
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
  
  def file_path(full: false)
    tmp_folder = self.file_folder == '.' ? '' : self.file_folder
    tmp_path = File.join self.category, tmp_folder, self.file_name
    full ? File.join(Setting['dir.sorted'], tmp_path) : tmp_path
  end # file_path
  
  def file_contents
    File.read self.file_path(full: true)
  end # file_contents
  
  # infer a default artist and filename
  def file_dl_info
    return @file_dl_info if @file_dl_info
  
    @file_dl_info = {}
    
    tmp_folder = self.file_folder == '.' ? '' : self.file_folder
    
    case self.category
      when 'author', 'circle'
        tmp_author, tmp_subfolder = tmp_folder.split(File::SEPARATOR, 2)
        @file_dl_info[:author  ] = tmp_author
        @file_dl_info[:filename] = self.file_name
        @file_dl_info[:filename] = "#{tmp_subfolder} -- #{@file_dl_info[:filename]}" if tmp_subfolder
      when 'artbook', 'magazine'
        tmp_folder, tmp_subfolder = tmp_folder.split(File::SEPARATOR, 2)
        @file_dl_info[:author  ] = 'various'
        @file_dl_info[:filename] = "{#{self.category[0..2]}} "
        @file_dl_info[:filename] += "#{tmp_folder} #{'-- ' if self.category == 'artbook'}" if tmp_folder.present?
        @file_dl_info[:filename] += "- #{tmp_subfolder} " if tmp_subfolder.present?
        @file_dl_info[:filename] += self.file_name
    end
    
    @file_dl_info[:ext] = File.extname @file_dl_info[:filename]
    @file_dl_info[:filename] = File.basename @file_dl_info[:filename], @file_dl_info[:ext]
    
    @file_dl_info
  end # file_dl_info
  
  def file_dl_name
    return @file_dl_name if @file_dl_name
    
    info = self.file_dl_info
    
    @file_dl_name = case self.category
      when 'author', 'circle'   ; "[#{info[:author]}] #{info[:filename]}#{info[:ext]}"
      when 'artbook', 'magazine'; "#{info[:filename]}#{info[:ext]}"
    end
  end # file_dl_name
  
  def thumb_path = "/thumbs/#{self.id}.webp"
  
  def destroy_with_files
    @delete_files = true
    self.destroy
  end # destroy_with_files
  
  def percent_read = (read_pages.to_f / num_images * 100).round(2)
  
  
  private # ____________________________________________________________________
  
  
  def delete_files
    return unless @delete_files
    [
      self.file_path(full: true), # doujin file
      File.join(Rails.root, 'public', 'thumbs', "#{self.id}.webp"), # thumbnail
    ].each{|f| File.unlink(f) if File.exist?(f) }
  end # delete_files
end
