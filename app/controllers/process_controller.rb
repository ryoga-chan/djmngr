class ProcessController < ApplicationController
  before_action :check_archive_file  , only: [:prepare_archive, :delete_archive]
  before_action :check_archive_folder, only: [
    :edit, :show_image,
    :delete_archive_cwd, :delete_archive_files,
    :rename_images, :rename_file,
  ]

  # list processable files
  def index
    @files = Dir
      .chdir(Setting['dir.to_sort']) do
        Dir['**/*.zip'].sort.inject({}){|h, f| h.merge f => File.size(f) }
      end
    
    @preparing = Dir
      .chdir(Setting['dir.sorting']){
        Dir['**/info.yml'].map{|f|
          tot_size = Dir
            .glob("#{File.dirname f}/**/*")
            .map{|f| f.ends_with?('/file.zip') ? 0 : File.size(f) }
            .sum
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
      
      PrepareArchiveForProcessingJob.perform_later dst_dir
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
  
  # manage archive operations (sanitize filenames, delete extra images, identify author)
  def edit
    params[:tab] = 'files' unless %w{ files images ident }.include?(params[:tab])
    
    @info = YAML.load_file(File.join @dname, 'info.yml')
    @perc = File.read(File.join @dname, 'completion.perc').to_f rescue 0.0 unless @info[:prepared_at]
    
    if params[:tab] == 'ident'
      # toggle association by single ID
      %w{ author circle }.each do |k|
        if params["#{k}_id".to_sym]
          @info["#{k}_ids".to_sym] ||= []
          method = @info["#{k}_ids".to_sym].to_a.include?(params["#{k}_id".to_sym].to_i) ? :delete : :push
          @info["#{k}_ids".to_sym].send method, params["#{k}_id".to_sym].to_i
          File.open(File.join(@dname, 'info.yml'), 'w'){|f| f.puts @info.to_yaml }
          return redirect_to(edit_process_path(id: params[:id], tab: 'ident', term: params[:term]))
        end
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
    end
  end # edit
  
  def rename_images
    @info = YAML.load_file(File.join @dname, 'info.yml')
    
    begin
      case params[:rename_with].to_sym
        when :alphabetical_index
          @info[:images].each_with_index{|img, i| img[:dst_path] = '%04d.jpg' % (i+1) }
        when :to_integer
          @info[:images].each{|img| img[:dst_path] = '%04d.jpg' % img[:src_path].to_i }
        when :regex_number
          re = Regexp.new params[:rename_regexp]
          @info[:images].each do |img|
            img[:dst_path] = '%04d.jpg' % img[:src_path].match(re)&.captures&.first.to_i
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
            .each_with_index{|img, i| img[:dst_path] = '%04d.jpg' % (i+1) }
        else
          raise 'unknown renaming method'
      end # case
      
      @info[:images] = @info[:images].sort{|a,b| a[:dst_path] <=> b[:dst_path] }
      
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
