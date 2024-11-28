# find a MIME type descr by extension
#   Marcel::MimeType.for(extension: :webp)
# list of all currently registered MIME types
#   Mime::EXTENSION_LOOKUP.map{|x| x}.sort
#   Mime::Type.lookup_by_extension(:pdf) # or look up by type
Mime::Type.register 'text/html'                , :ereader
Mime::Type.register 'application/zip'          , :cbz
Mime::Type.register 'application/epub+zip'     , :epub
Mime::Type.register 'text/tab-separated-values', :tsv
