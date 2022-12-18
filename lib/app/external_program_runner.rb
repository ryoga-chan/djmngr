module ExternalProgramRunner
  def self.run(program, target, options = {})
    env = Setting.get_json(:ext_cmd_env).to_h
    
    case program
      when 'file_manager' ; system env, %Q| #{Setting[:file_manager ]} #{target.shellescape} & |, options
      when 'image_editor' ; system env, %Q| #{Setting[:image_editor ]} #{target.shellescape} & |, options
      when 'terminal'     ; system env, %Q| #{Setting[:terminal     ]} & |, options.merge(chdir: target)
      when 'comics_viewer'; system env, %Q| #{Setting[:comics_viewer]} #{target.shellescape} & |, options
      when 'batch_comics_viewer' # read a batch of files
        system env, %Q| #{Setting[:comics_viewer]} #{target.to_a.map(&:shellescape).join ' '} & |, options
    end
  end # run
end # ExternalProgramRunner
