module ExternalProgramRunner
  def self.run(program, file)
    env = Setting.get_json(:ext_cmd_env).to_h
    
    case program
      when 'comics_viewer'; system env, %Q| #{Setting[:comics_viewer]} #{file.shellescape} & |
      when 'file_manager' ; system env, %Q| #{Setting[:file_manager ]} #{file.shellescape} & |
      when 'image_editor' ; system env, %Q| #{Setting[:image_editor ]} #{file.shellescape} & |
      when 'terminal'     ; system env, %Q| #{Setting[:terminal     ]} & |, chdir: file
    end
  end # run
end # ExternalProgramRunner
