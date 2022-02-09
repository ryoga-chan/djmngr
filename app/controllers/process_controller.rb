class ProcessController < ApplicationController
  before_action :check_archive_file  , only: [:prepare_archive, :delete_archive]
  before_action :check_archive_folder, only: [
    :edit, :set_property, :finalize_volume,
    :show_image, :rename_images, :rename_file,
    :delete_archive_cwd, :delete_archive_files,
  ]

  # list processable files
  def index
    # create archive folders
    folders  = [ Setting['dir.to_sort'], Setting['dir.sorting'] ]
    folders += %w{ author circle magazine artbook }.map{|d| File.join(Setting['dir.sorted'], d).to_s }
    folders.each{|f| FileUtils.mkdir_p f }
    
    @files = Dir.chdir(Setting['dir.to_sort']) do
      Dir['**/*.zip'].sort.inject({}){|h, f| h.merge f => File.size(f) }
    end
    
    @preparing = Dir.chdir(Setting['dir.sorting']){
      Dir['**/info.yml'].map{|f|
        tot_size = Dir.glob("#{File.dirname f}/**/*").
          map{|f| f.ends_with?('/file.zip') ? 0 : File.size(f) }.sum
        YAML.load_file(f).merge tot_size: tot_size
      }
    }.sort{|a,b| a[:relative_path] <=> b[:relative_path] }
    
    @preparing_paths = @preparing.map{|i| i[:relative_path] }
  end # index
  
  # prepare ZIP working folder and redirects to edit
  def prepare_archive
    if Marcel::MimeType.for(Pathname.new @fname) != 'application/zip'
      return redirect_to(process_index_path, alert: "incorrect MIME type, it's not a ZIP file!")
    end
    
    file_size = File.size @fname
    
    # create WIP folder named as the hash
    hash = Digest::SHA256.hexdigest "djmngr|#{File.basename @fname}|#{file_size}"
    dst_dir = File.join Setting['dir.sorting'], hash
    FileUtils.mkdir_p dst_dir
    
    if Dir.empty?(dst_dir)
      # create metadata file
      File.open(File.join(dst_dir, 'info.yml'), 'w') do |f|
        f.puts({
          file_path:     @fname,
          file_size:     file_size,
          relative_path: params[:path],
          working_dir:   hash,
          prepared_at:   nil,
        }.to_yaml)
      end
      
      # create a symlink just in case of manual folder inspection (unsupported on windows)
      File.symlink @fname, File.join(dst_dir, 'file.zip') rescue nil
      
      ProcessArchiveDecompressJob.perform_later dst_dir
    end
    
    redirect_to edit_process_path(id: hash)
  end # prepare_archive
  
  def delete_archive
    File.unlink @fname
    return redirect_to(process_index_path, notice: "file deleted: [#{@fname}]") 
  end # delete_archive
  
  def delete_archive_cwd
    if params[:archive_too] == 'true'
      @info = YAML.load_file(File.join @dname, 'info.yml')
      File.unlink @info[:file_path]
    end
    
    FileUtils.rm_rf @dname, secure: true
    
    msg = params[:archive_too] == 'true' ?
      "archive and folder deleted: [#{@info[:relative_path]}], [#{params[:id]}]" :
      "folder deleted: [#{params[:id]}]"
    return redirect_to(process_index_path, notice: msg)
  end # delete_archive_cwd
  
  def delete_archive_files
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    params[:path] = [ params[:path] ] unless params[:path].is_a?(Array)
    
    params[:path].each do |path|
      if idx = @info[:files].index{|i| i[:src_path] == path }
        @info[:files].delete_at idx
        FileUtils.rm_f File.join(@dname, 'contents', path)
      else
        if idx = @info[:images].index{|i| i[:src_path] == path }
          @info[:images].delete_at idx
          FileUtils.rm_f File.join(@dname, 'contents', path)
        end
      end
    end
    
    File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
    
    return redirect_to(edit_process_path(id: params[:id], tab: params[:tab]),
      notice: "#{params[:path].size} file/s deleted")
  end # delete_archive_files
  
  def set_property
    @info  = YAML.load_file(File.join @dname, 'info.yml')
    @perc  = File.read(File.join @dname, 'completion.perc').to_f rescue 0.0 unless @info[:prepared_at]
    @fname = File.basename(@info[:relative_path].to_s)
    info_changed = false

    # set file type
    if params[:file_type] && params[:file_type] != @info[:file_type]
      @info[:file_type] = params[:file_type].strip
      info_changed = true
    end
    
    # DOUJIN: toggle associated author/circle ID
    %w{ author circle }.each do |k|
      tmp_id = params["#{k}_id".to_sym].to_i
      
      if tmp_id > 0
        key = "#{k}_ids".to_sym
        @info[key] ||= []
        method = @info[key].to_a.include?(tmp_id) ? :delete : :push
        @info[key].send method, tmp_id
        # remove destination if deleting it
        @info[:doujin_dest_id] = nil if method == :delete && @info[:doujin_dest_id] == "#{k}-#{tmp_id}"
        info_changed = true
      end
    end
    
    # DOUJIN: select a main/destination author/circle
    if params[:doujin_dest_id] && params[:doujin_dest_id] != "#{@info[:doujin_dest_type]}-#{@info[:doujin_dest_id]}"
      # store type and ID
      @info[:doujin_dest_type], @info[:doujin_dest_id] = params[:doujin_dest_id].split('-')
      # set destination folder to subject romaji name
      subject = @info[:doujin_dest_type].capitalize.constantize.find_by(id: @info[:doujin_dest_id])
      @info[:dest_folder] = (subject.name_romaji || subject.name_kakasi).downcase.strip
      info_changed = true
    end
    
    # set destination folder
    if params[:dest_folder] && params[:dest_folder] != @info[:dest_folder]
      @info[:dest_folder] = params[:dest_folder].strip
      info_changed = true
    end
    
    # set destination folder
    if params[:subfolder] && params[:subfolder] != @info[:subfolder]
      @info[:subfolder] = params[:subfolder].strip
      info_changed = true
    end
    
    # set destination filename
    if params[:dest_filename] && params[:dest_filename] != @info[:dest_filename]
      @info[:dest_filename] = params[:dest_filename].strip
      info_changed = true
    end

    # toggle overwrite of file in the collection
    if params[:overwrite] && (params[:overwrite].to_i == 1) != @info[:overwrite]
      @info[:overwrite] = params[:overwrite].to_i == 1
      info_changed = true
    end

    # set doujin scoring
    if params[:score] && params[:score].to_i != @info[:score]
      @info[:score] = params[:score].to_i
      info_changed = true
    end
    
    File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml } if info_changed
    
    redirect_to edit_process_path(id: params[:id], tab: params[:tab], term: params[:term])
  end # set_property
  
  # manage archive operations (sanitize filenames, delete extra images, identify author)
  def edit
    params[:tab] = 'files' unless %w{ files images ident move }.include?(params[:tab])
    
    @info  = YAML.load_file(File.join @dname, 'info.yml')
    @perc  = File.read(File.join @dname, 'completion.perc').to_f rescue 0.0 unless @info[:prepared_at]
    @fname = File.basename(@info[:relative_path].to_s)
    
    if params[:tab] == 'ident'
      # list possible dest folders
      @dest_folders = []
      case @info[:file_type]
        when 'doujin'
          if @info[:doujin_dest_type]
            repo = File.join(Setting['dir.sorted'], @info[:doujin_dest_type]).to_s
            @dest_folders = Dir.chdir(repo){ Dir['*'].select{|i| File.directory? i } }.sort.unshift('-custom name-')
          end
        when 'magazine'
          repo = File.join(Setting['dir.sorted'], 'magazine').to_s
          @dest_folders = Dir.chdir(repo){ Dir['*'].select{|i| File.directory? i } }.sort.unshift('-custom name-')
        when 'artbook'
          repo = File.join(Setting['dir.sorted'], 'artbook').to_s
          @dest_folders = Dir.chdir(repo){ Dir['*'].select{|i| File.directory? i } }.sort.unshift('-custom name-')
      end
      
      # lists of currently associated authors/circles
      @associated_authors = Author.where(id: @info[:author_ids]).order("LOWER(name), id DESC")
      @associated_circles = Circle.where(id: @info[:circle_ids]).order("LOWER(name), id DESC")
      
      # filename analisys
      @name = File.basename(@info[:relative_path].to_s).parse_doujin_filename
      # single term search
      params[:term] = @name[:ac_explicit][0] || @name[:ac_implicit][0] if params[:term].blank?
      @authors = Author.search_by_name params[:term], limit: 50
      @circles = Circle.search_by_name params[:term], limit: 50
    end # tab 'ident'
    
    if params[:tab] == 'move'
      collection_file_path = Doujin.dest_path_by_process_params(@info, full_path: true)
      if File.exist?(collection_file_path)
        doujin = Doujin.find_by_process_params(@info)
        
        c_size = render_to_string inline: %Q|<%= number_to_human_size #{File.size collection_file_path} %>|
        c_imgs = doujin.try(:num_images) || 'N.D.'
        f_size = render_to_string inline: %Q|<%= number_to_human_size #{File.size @info[:file_path]} %>|
        f_imgs = @info[:images].size
        
        @collision_info = {
          collection: "#{c_imgs} pics/#{c_size}",
          current: "#{c_imgs} pics/#{c_size}",
          doujin: doujin
        }
      end
      
      # list possible dest subfolders
      @subfolders = ['-custom name-']
      repo = @info[:file_type] == 'doujin' ?
        File.join(Setting['dir.sorted'], @info[:doujin_dest_type], @info[:dest_folder]).to_s :
        File.join(Setting['dir.sorted'], @info[:file_type], @info[:dest_folder]).to_s
      @subfolders += Dir.chdir(repo){ Dir['*'].select{|i| File.directory? i } }.sort if File.exist?(repo)
    end # tab 'move'
  end # edit
  
  def rename_images
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    begin
      case params[:rename_with].to_sym
        when :alphabetical_index
          @info[:images].each_with_index{|img, i| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % (i+1) }
        when :to_integer
          @info[:images].each{|img| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % img[:src_path].to_i }
        when :regex_number
          re = Regexp.new params[:rename_regexp]
          @info[:images].each do |img|
            img[:dst_path] = "%04d#{File.extname img[:src_path]}" % img[:src_path].match(re)&.captures&.first.to_i
          end
        when :regex_pref_num, :regex_num_pref
          re = Regexp.new params[:rename_regexp]
          invert_terms = params[:rename_with].to_sym == :regex_num_pref
          # create a sortable label
          @info[:images].each do |img|
            prefix, num = img[:src_path].match(re)&.captures
            num, prefix = prefix, num if invert_terms
            img[:dst_sort_by] = "#{prefix}-#{'%050d' % num.to_i}"
          end
          # rename images sorted by the previous label
          @info[:images]
            .sort{|a,b| a[:dst_sort_by] <=> b[:dst_sort_by] }
            .each_with_index{|img, i| img[:dst_path] = "%04d#{File.extname img[:src_path]}" % (i+1) }
        else
          raise 'unknown renaming method'
      end # case
      
      @info[:images] = @info[:images].sort{|a,b| a[:dst_path] <=> b[:dst_path] }
      
      @info[:ren_images_method] = params[:rename_with]
      @info[:images_last_regexp] = params[:rename_regexp]
      @info[:images_collision] = @info[:images].size != @info[:images].map{|i| i[:dst_path] }.uniq.size
      
      File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
      
      redirect_to edit_process_path(id: params[:id])
    rescue
      redirect_to(edit_process_path(id: params[:id]), alert: $!.to_s)
    end
  end # rename_images
  
  def rename_file
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    if el = @info[:files].detect{|i| i[:src_path] == params[:path] }
      el[:dst_path] = params[:name]
      @info[:files] = @info[:files].sort{|a,b| a[:dst_path] <=> b[:dst_path] }
      @info[:files_collision] = @info[:files].size != @info[:files].map{|i| i[:dst_path] }.uniq.size
    elsif el = @info[:images].detect{|i| i[:src_path] == params[:path] }
      el[:dst_path] = params[:name]
      @info[:images] = @info[:images].sort{|a,b| a[:dst_path] <=> b[:dst_path] }
      @info[:images_collision] = @info[:images].size != @info[:images].map{|i| i[:dst_path] }.uniq.size
    end
    
    if el
      File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
      render(json: {result: 'ok'})
    else
      render(json: {result: 'err', msg: "image not found [#{params[:name]}]" })
    end
  end # rename_file
  
  def show_image
    sub_path = File.expand_path(params[:path], '/')[1..-1] # sanitize input
    send_file File.join(@dname, 'contents', sub_path), disposition: :inline
  end # show_image
  
  # rezip archive, add metadata, move/register in collection, cleaup WIP folder
  def finalize_volume
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    unless @info[:dest_folder].present? && @info[:dest_filename].present?
      return redirect_to(edit_process_path(id: params[:id], tab: 'ident'), alert: "empty destination folder or filename")
    end
    
    if @info[:overwrite] != true && @info[:db_doujin_id].nil? &&
       File.exist?(Doujin.dest_path_by_process_params(@info, full_path: true))
      return redirect_to(edit_process_path(id: params[:id], tab: 'move'), alert: "file already exists in collection")
    end
    
    perc_file = File.join(@dname, 'finalize.perc')
    @perc = File.read(perc_file).to_f rescue 0.0
    
    if params[:undo] && File.exist?(perc_file)
      File.unlink(perc_file)
      File.unlink(@info[:collection_full_path].to_s) if File.exist?(@info[:collection_full_path].to_s)
      return redirect_to(edit_process_path(id: params[:id]), notice: "finalize processing halted")
    end
    
    unless File.exist?(perc_file)
      FileUtils.touch perc_file
      ProcessArchiveCompressJob.perform_later @dname
    end
  end # finalize_volume
  
  
  private # ____________________________________________________________________
  
  
  def check_archive_file
    @fname = File.expand_path File.join(Setting['dir.to_sort'], params[:path])
    
    return redirect_to(process_index_path, alert: "file not found!") unless File.exist?(@fname)
    
    unless @fname.start_with?(Setting['dir.to_sort'])
      return redirect_to(process_index_path, alert: "file outside of working directory!")
    end
  end # check_archive_file
  
  def check_archive_folder
    @dname = File.expand_path File.join(Setting['dir.sorting'], params[:id])
    
    return redirect_to(process_index_path, alert: "folder not found!") unless File.exist?(@dname)
    
    unless @dname.start_with?(Setting['dir.sorting'])
      return redirect_to(process_index_path, alert: "folder outside of working directory!")
    end
  end # check_archive_folder
end
