module ExternalProgramRunner
  def self.run(program, target)
    env = Setting.get_json(:ext_cmd_env).to_h
    
    case program
      when 'comics_viewer'; system env, %Q| #{Setting[:comics_viewer]} #{target.shellescape} & |
      when 'file_manager' ; system env, %Q| #{Setting[:file_manager ]} #{target.shellescape} & |
      when 'image_editor' ; system env, %Q| #{Setting[:image_editor ]} #{target.shellescape} & |
      when 'terminal'     ; system env, %Q| #{Setting[:terminal     ]} & |, chdir: target
    end
  end # run
end # ExternalProgramRunner
