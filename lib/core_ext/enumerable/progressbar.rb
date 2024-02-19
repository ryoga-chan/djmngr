module CoreExt::Enumerable::Progressbar
  # https://stackoverflow.com/questions/27735110/how-to-add-methods-to-the-enumerable-module
  module ::Enumerable
    PROGRESSBAR_OPTIONS = {
      starting_at:    0,
      total:          100,
      length:         74,
      progress_mark:  '#',
      remainder_mark: '_',
      title:          'steps',
      format:         '%t: %J%% [%B] %e',
    }

    def create_progressbar(options = {})
      ProgressBar.create PROGRESSBAR_OPTIONS.
        merge({ total: (respond_to?(:length) ? self.length : 100) }).
        merge(options)
    end # create_progressbar

    # shortcut
    def self.create_progressbar(total, title = 'steps') = ProgressBar.
      create(PROGRESSBAR_OPTIONS.merge(total: total, title: title))

    self.singleton_class.send :alias_method, :create_pb, :create_progressbar

    def each_with_progressbar(options = {})
      pb = self.create_progressbar options

      each do |item|
        result = yield item, pb
        pb.increment
        result
      end
    end # each_with_progressbar --------------------------------------------------
    alias :each_with_pb           :each_with_progressbar
    alias :each_with_progress_bar :each_with_progressbar

    def map_with_progressbar(options = {})
      pb = self.create_progressbar options

      map do |item|
        result = yield item, pb
        pb.increment
        result
      end
    end # map_with_progressbar ---------------------------------------------------
    alias :map_with_pb            :map_with_progressbar
    alias :map_with_progress_bar  :map_with_progressbar
  end # module Enumerable
end
