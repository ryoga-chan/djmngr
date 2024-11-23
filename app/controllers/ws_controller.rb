class WsController < ApplicationController
  DL_IMAGE_ZIPNAME = 'ws downloaded images'

  def ehentai = render json: Ws::EHentai.search(params[:term])

  def to_romaji = render plain: params[:s].to_s.to_romaji.strip

  # params: :u = source url, :n = dest filename, :t = dest folder,
  #         :s = scale resolution XxY, :r = referer
  def dl_image
    url = URI.parse params[:u] rescue nil
    return render(json: { result: :err, msg: 'invalid/empty parameter "u"' }) if url.nil? || url.class == URI::Generic

    zip_name = File.basename(params[:t] || DL_IMAGE_ZIPNAME).to_s.to_sanitized_filename[...251] + '.zip'
    zip_file = Rails.root.join('tmp', zip_name).to_s
    # create empty ZIP file
    Zip::File.open(zip_file, create: true){} unless File.exist?(zip_file)
    # create processing folder
    hash = ProcessArchiveDecompressJob.prepare_and_perform zip_file, perform_when: :now, dummy: true

    # download file
    resp, file_name_dst, file_name_src, file_contents = nil, nil, nil, nil

    case url.host
      when 'e-hentai.org', 'exhentai.org'
        case result = Ws::EHentai.dl_image(params[:u])
          when Symbol then resp = result
          when Hash   then resp, file_name_src = result[:resp], result[:filename]
        end
      else
        begin
          resp = Ws::EHentai::REQ.
            with(timeout: { request_timeout: 10 }).
            with(headers: { 'User-Agent' => Setting['scraper_useragent'], 'Referer' => params[:r] }).
            get(params[:u])
        rescue HTTPX::TimeoutError
          resp = :timeout
        end
    end

    file_contents = resp.try(:body).to_s
    resp.try(:body)&.close # remove HTTPX tempfile

    error = case
      when resp.is_a?(Symbol) then { result: :err, msg: resp }
      when resp.is_a?(HTTPX::ErrorResponse) || resp&.status != 200
        { result: :err, msg: 'remote server errror' }
    end
    return render(json: error) if error

    # set destination file name
    if file_name_dst = params[:n]
      file_name_src ||= file_name_dst
    else
      if file_name_src.present?
        file_name_dst = file_name_src
      else
        begin
          ext  = Marcel::TYPE_EXTS[ resp.content_type.as_json['header_value'] ]&.first || 'bin'
          name = URI.split(params[:u])[2..].compact.join('_').to_sanitized_filename
          file_name_src = "#{name[..(254 - ext.size)]}.#{ext}"
          file_name_dst = file_name_src.is_image_filename? ? file_name_src : "#{name[..251]}.jpg"
        rescue
          return render(json: { result: :err, msg: $!.to_s })
        end
      end
    end

    # inject file
    ext_dst, ext_src = File.extname(file_name_dst).downcase, File.extname(file_name_src).downcase
    to_scale, dst_w, dst_h = params[:s].to_s =~ /\A(\d+)*x(\d+)*\z/, $1, $2
    Tempfile.open(['djmngr-ws-dl_image-', ext_dst], binmode: true) do |f|
      begin
        if file_name_src.is_image_filename? && (ext_dst != ext_src || to_scale)
          vips  = Vips::Image.new_from_buffer file_contents, ''
          vips  = vips.downsize_to dst_w, dst_h if to_scale
          # https://www.rubydoc.info/gems/ruby-vips/Vips/Image:write_to_buffer
          kargs = ext_dst.in?(%w[ .jpg .png .webp ]) ? { Q: IMG_QUALITY_RESIZE } : {}
          f.write vips.write_to_buffer(ext_dst, **kargs)
        else
          f.write file_contents
        end
      rescue
        f.close
        f.unlink
        return render(json: { result: :err, msg: "image conversion error:\n#{$!}" })
      end
      f.close
      ProcessArchiveDecompressJob.inject_file file_name_dst, f.path, hash, save_info: true, check_collisions: true
      f.unlink
    end

    render json: { result: :ok }
  end # dl_image
end
