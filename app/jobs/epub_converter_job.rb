class EpubConverterJob < ApplicationJob
  queue_as :tools
  
  def perform(doujin_id, options = {})
    options[:name  ] ||= 'default'
    options[:width ] =  768 unless (320..3000).include?(options[:width ].to_i)
    options[:height] = 1024 unless (320..3000).include?(options[:height].to_i)
    
    doujin = Doujin.find(doujin_id)
    
    # working folder
    base_dir = Rails.root.join('public', 'epub').to_s
    tmpd = File.join base_dir, doujin.file_dl_name.sub(/zip$/i, 'wip')
    perc_file = tmpd.sub(/wip$/i, 'perc')
    
    return if File.exist?(tmpd) # noop if already running
    FileUtils.mkdir_p tmpd
    
    # epub unique identifier
    uuid = SecureRandom.uuid
    
    # target image dimensions
    width_dst  = options[:width ].to_i
    height_dst = options[:height].to_i
    
    fname_src  = doujin.file_path(full: true)
    fname_dst  = File.join base_dir,
      doujin.file_dl_name.tr('!', '_').sub(/\.zip$/i, "@#{options[:name]}.kepub.epub")
    author     = doujin.file_dl_info[:author]
    title      = doujin.file_dl_info[:filename]
    
    crop_modes = [:high, :low]
    crop_modes.reverse! if doujin.reading_direction == 'l2r'
    
    # stop the job and write output to logfile
    die = Proc.new  do |msg|
      fname = File.join(tmpd, 'error.log')
      File.open(fname, 'w'){|f| f.puts msg}
      return
    end
    
    # create required folders
    %w{ META-INF images pages }.each{|d| FileUtils.mkdir_p "#{tmpd}/#{d}" }
    
    puts "Converting images..."
    images = []
    Zip::File.open(fname_src) do |zip|
      entries = zip.image_entries(sort: true)
      
      entries.each_with_index do |entry, i|
        puts entry.name
        
        perc = (i+1).to_f / entries.size * 100
        File.atomic_write(perc_file){|f| f.write perc.round(2) }
        
        img_dst = "#{tmpd}/images/#{'%04d' % (i+1)}"
        
        # read image in memory
        img = Vips::Image.new_from_buffer entry.get_input_stream.read, ''
        
        if img.width > img.height # landscape image => generate 3 images:
          # NOTE: ImageProcessing::Vips does not upscale the image!! => so we use Vips::Image
          #im = ImageProcessing::Vips.source(img).convert('jpg').saver(quality: IMG_QUALITY_RESIZE)
          
          # 90° rotated image
          fname = "#{img_dst}-0.jpg"; puts "\t rotated"
          #im.rotate(90).resize_and_pad(width_dst, height_dst, background: [255,255,255]).call destination: fname
          img2 = img.rotate(90).resize_to_fit(width_dst, height_dst)
          if img2.height < height_dst
            # https://github.com/libvips/ruby-vips/issues/134#issuecomment-330685115
            # add top/bottom white border to center image in the epub page
            margin_top = (height_dst - img2.height)/2
            img2 = img2.embed \
              0,         margin_top, # current image insertion coordinates (X, Y)
              width_dst, height_dst, # canvas/larger image dimensions
              background: [255,255,255]
          end
          img2.write_to_file fname, Q: IMG_QUALITY_RESIZE
          images << File.basename(fname)
          
          # doubled image for halving
          #im = im.resize_to_fit(width_dst*2, height_dst)
          img2 = img.resize_to_fit width_dst*2, height_dst
          
          # first part of the splitted half
          fname = "#{img_dst}-1.jpg"; puts "\t first half (#{crop_modes[0]})"
          #im.resize_to_fit(width_dst*2, height_dst).resize_to_fill(width_dst, height_dst, crop: crop_modes[0]).call destination: fname
          img2.smartcrop(width_dst, height_dst, interesting: crop_modes[0]).write_to_file fname
          images << File.basename(fname)
          
          # second part of the splitted half
          fname = "#{img_dst}-2.jpg"; puts "\t second half (#{crop_modes[1]})"
          #im.resize_to_fit(width_dst*2, height_dst).resize_to_fill(width_dst, height_dst, crop: crop_modes[1]).call destination: fname
          img2.smartcrop(width_dst, height_dst, interesting: crop_modes[1]).write_to_file fname
          images << File.basename(fname)
        else # resize the image
          fname = "#{img_dst}.jpg"
          #ImageProcessing::Vips.source(img).resize_and_pad(width_dst, height_dst, background: [255,255,255]).call destination: fname
          img.resize_to_fit(width_dst, height_dst).write_to_file fname, Q: IMG_QUALITY_RESIZE
          images << File.basename(fname)
        end
      end # each zip entry
    end # Zip open

    # check images presence
    die "no images found" if images.empty?
    
    puts "Creating metadata..."
    
    File.open("#{tmpd}/mimetype",'w'){|f| f.write "application/epub+zip" }
    
    File.open("#{tmpd}/page.css",'w'){|f|
      f.puts <<~CSS
        @page, html, body, div.main, img { margin: 0; padding:0; }
        div.main { width: 100%; text-align: center; }
        img.page.fit-height { height: 100%; margin: 0 auto; }
        img.page.fit-width  { width:  100%; margin: auto 0; }
      CSS
    }
    
    File.open("#{tmpd}/META-INF/container.xml",'w'){|f|
      f.puts <<~XML
        <?xml version="1.0"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
      XML
    }
    
    items = {page: [], image: [], spine: [], toc: []}
    
    images.each_with_index do |img_name, i|
      num = '%04d' % (i+1)
      
      items[:page ] << %Q|    <item id="p#{num}" href="pages/#{num}.xhtml" media-type="application/xhtml+xml"/>|
      items[:image] << %Q|    <item id="i#{num}" href="images/#{img_name}" media-type="image/jpeg"#{' properties="cover-image"' if i == 0}/>|
      items[:spine] << %Q|    <itemref idref="p#{num}"/>|
      items[:toc  ] << %Q|    <navPoint id="n#{i+1}" playOrder="#{i+1}" class="chapter"><navLabel><text>Page #{i+1}</text></navLabel><content src="pages/#{num}.xhtml"/></navPoint>|
      
      # create XHTML page
      img_type = img_name =~ /....-[12]\.jpg/ ? 'fit-width' : 'fit-height'
      File.open("#{tmpd}/pages/#{num}.xhtml",'w') do |f|
        f.puts <<~XHTML
          <?xml version="1.0" encoding="UTF-8"?>
          <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
          <head>
            <title>page #{num}</title>
            <link rel="stylesheet" type="text/css" href="../page.css"/>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <meta name="viewport" content="width=#{width_dst}, height=#{height_dst}"/>
          </head>
          <body>
            <div class="main">
              <img src="../images/#{img_name}" alt="page #{num}" class="page #{img_type}" width="#{width_dst}" height="#{height_dst}"/>
            </div>
          </body>
          </html>
        XHTML
      end
    end # each image
    
    File.open("#{tmpd}/content.opf",'w') do |f|
      f.puts <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!-- https://wiki.mobileread.com/wiki/EPUB -->
        <!-- https://github.com/kobolabs/epub-spec -->
        <!-- https://gist.github.com/daniel-j/613a506a0ec9c7037897c4b3afa8e41e -->
        <package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="uuid_id">
          <metadata xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <dc:title>#{title.encode xml: :text}</dc:title>
            <dc:creator opf:role="aut">#{author.encode xml: :text}</dc:creator>
            <dc:identifier id="uuid_id" opf:scheme="uuid">#{uuid}</dc:identifier>
            <dc:language>en</dc:language>
            <meta property="rendition:orientation">portrait</meta>
            <meta property="rendition:spread">portrait</meta>
            <meta property="rendition:layout">pre-paginated</meta>
            <meta name="cover" content="i0001"/>
          </metadata>
          <manifest>
        #{items[:page ].join "\n"}
          
        #{items[:image].join "\n"}
          
            <item id="page_css" href="page.css" media-type="text/css"/>
            <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
          </manifest>
          <spine toc="ncx">
        #{items[:spine].join "\n"}
          </spine>
        </package>
      XML
    end
    
    File.open("#{tmpd}/toc.ncx",'w') do |f|
      f.puts <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!-- https://wiki.mobileread.com/wiki/NCX -->
        <!-- https://docs.fileformat.com/ebook/ncx/ -->
        <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="eng">
          <head>
            <meta name="dtb:uid" content="#{uuid}"/>
            <meta name="dtb:depth" content="1"/>
            <meta name="dtb:totalPageCount" content="0"/>
            <meta name="dtb:maxPageNumber" content="0"/>
          </head>
          <docTitle><text>#{title.encode xml: :text}</text></docTitle>
          <docAuthor><text>#{author.encode xml: :text}</text></docAuthor>
          <navMap>
        #{items[:toc].join "\n"}
          </navMap>
        </ncx>
      XML
    end

    puts "Creating epub file..."
    File.unlink fname_dst if File.exist?(fname_dst)
    [ %Q[ zip -q0X #{fname_dst.shellescape} mimetype ],
     #%Q[ zip -q9XrD #{fname_dst.shellescape} * -x mimetype ],
      %Q[ find -type f | grep -v "mimetype\\|pages\\|jpg" | sort | zip -q9XrD@ #{fname_dst.shellescape} ],
      %Q[ find -type f | grep pages                       | sort | zip -q9XrD@ #{fname_dst.shellescape} ],
      %Q[ find -type f | grep jpg                         | sort | zip -q9XrD@ #{fname_dst.shellescape} ],
    ].each do |cmd|
      system cmd, chdir: tmpd
      die "ZIP create error: #{$?.to_i}" if $?.to_i != 0
    end
    
    FileUtils.rm_rf tmpd
    File.unlink perc_file if File.exist?(perc_file)
  end # perform
end
