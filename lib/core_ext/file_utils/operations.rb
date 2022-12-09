module CoreExt
  module FileUtils
    module Operations
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        # append string to filename
        def cp_f(src, dst)
          File.unlink dst if File.exist?(dst)
          ::FileUtils.cp src, dst
        end # self.cp_f
      end
    end
  end
end

FileUtils.send :include, CoreExt::FileUtils::Operations
