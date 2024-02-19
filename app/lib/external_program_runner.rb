module ExternalProgramRunner
  def self.run(program, target, options = {})
    env = Setting.get_json(:ext_cmd_env).to_h

    case program
      when 'file_manager' ; system env, %Q( #{Setting[:file_manager ]} #{target.shellescape} & ), options
      when 'image_editor' ; system env, %Q( #{Setting[:image_editor ]} #{target.shellescape} & ), options
      when 'terminal'     ; system env, %Q( #{Setting[:terminal     ]} & ), options.merge(chdir: target)
      when 'comics_viewer'; system env, %Q( #{Setting[:comics_viewer]} #{target.shellescape} & ), options
      when 'file_picker'  ; exec_with_timeout(Setting[:file_picker], 60).to_s.chomp
      when 'batch_comics_viewer' # read a batch of files
        system env, %Q( #{Setting[:comics_viewer]} #{target.to_a.map(&:shellescape).join ' '} & ), options
    end
  end # self.run

  # https://stackoverflow.com/questions/8292031/ruby-timeouts-and-system-commands/31465248#31465248
  def self.exec_with_timeout(cmd, timeout)
    begin
      # stdout, stderr pipes
      rout, wout = IO.pipe
      rerr, werr = IO.pipe
      stdout, stderr = nil

      pid = Process.spawn(cmd, pgroup: true, out: wout, err: werr)

      Timeout.timeout(timeout) do
        Process.waitpid(pid)

        # close write ends so we can read from them
        wout.close
        werr.close

        stdout = rout.readlines.join
        stderr = rerr.readlines.join
      end
    rescue Timeout::Error
      Process.kill(-9, pid)
      Process.detach(pid)
    ensure
      wout.close unless wout.closed?
      werr.close unless werr.closed?
      # dispose the read ends of the pipes
      rout.close
      rerr.close
    end

    stdout
  end # self.exec_with_timeout
end # ExternalProgramRunner
