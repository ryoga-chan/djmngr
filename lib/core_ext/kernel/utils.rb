module CoreExt
  module Kernel
    module Utils
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        # suppress stdout and/or stderr
        # https://gist.github.com/moertel/11091573  | moertel/suppress_ruby_output.rb
        def suppress_output(stdout: true, stderr: true)
          if stdout
            orig_stdout = $stdout.clone
            $stdout.reopen(File.new(File::NULL, 'w'))
          end
          
          if stderr
            orig_stderr = $stderr.clone
            $stderr.reopen(File.new(File::NULL, 'w'))
          end
          
          yield
        ensure
          $stdout.reopen orig_stdout if stdout
          $stderr.reopen orig_stderr if stderr
        end # suppress_output
      end # ClassMethods
    end
  end
end

Kernel.send :include, CoreExt::Kernel::Utils
