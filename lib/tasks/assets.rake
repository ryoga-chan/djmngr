namespace :assets do
  # https://github.com/rails/propshaft/issues/158#issuecomment-1786039189
  # https://github.com/rails/propshaft/pull/161#issuecomment-1788304229
  desc "Compress assets files for nginx delivery"
  task :compress do
    dst_dir = Rails.application.assets.config.output_path

    dst_dir.glob('**/*.{js,css,svg}').each do |src_path|
      dst_path = Pathname.new "#{src_path}.gz"
      next if File.exist?(dst_path)

      Propshaft.logger.info "Compressing #{dst_path.relative_path_from dst_dir}"

      Zlib::GzipWriter.open(dst_path, Zlib::BEST_COMPRESSION) do |gz|
        gz.mtime     = File.mtime    src_path
        gz.orig_name = File.basename src_path
        gz.write IO.binread(src_path)
      end
    end # each asset
  end # task assets:compress

  Rake::Task["assets:precompile"].enhance{ Rake::Task["assets:compress"].invoke }
end
