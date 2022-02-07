class ProcessArchiveCompressJob < ApplicationJob
  queue_as :tools

  def perform(src_dir)
    info = YAML.load_file(File.join src_dir, 'info.yml')
    
    out_dir = File.join src_dir, 'output'
    FileUtils.mkdir_p out_dir
    
      # write completion percentage
      #perc = (i+1).to_f / info[:images].size * 100
      perc = rand*100
      File.open(File.join(src_dir, 'finalize.perc'), 'w'){|f| f.write perc.round(2) }
    
    #File.open(File.join(dst_dir, 'info.yml'), 'w'){|f| f.puts info.to_yaml }
  end # perform
end
