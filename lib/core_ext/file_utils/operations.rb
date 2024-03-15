module CoreExt::FileUtils::Operations
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # append string to filename
    def cp_f(src, dst)
      File.unlink dst if File.exist?(dst)
      ::FileUtils.cp src, dst
    end # cp_f

    def cp_hard(src, dst, options = {})
      File.unlink dst if options[:force] && File.exist?(dst)
      
      if OS_LINUX
        File.link      src, dst # efficient copy via hard link
      else
        ::FileUtils.cp src, dst
      end
    end # cp_hard
  end
end

FileUtils.send :include, CoreExt::FileUtils::Operations
