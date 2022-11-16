# https://api.rubyonrails.org/classes/ActiveRecord/Batches.html
# ==> find_in_batches/find_each *ignores* any order clause
module CoreExt
  module ActiveRecord
    module Batches
      # emulate `find_in_batches` preserving records order
      def find_in_batches_in_order(batch_size: 1000)
        num_records      = self.reorder('').reselect('').count
        batches_interval = 0..(num_records/batch_size)
        
        if block_given?
          batches_interval.
            each{|i| yield self.offset(i*batch_size).limit(batch_size) if (i*batch_size) < num_records }
        else
          batches_interval.
            map{|i| self.offset(i*batch_size).limit(batch_size) if (i*batch_size) < num_records }.
            compact
        end
      end # find_in_batches_in_order
      
      # emulate `find_each` using find_in_batches_in_order
      def find_each_in_order(batch_size: 1000)
        if block_given?
          self.find_in_batches_in_order(batch_size: batch_size).
            each{|batch| batch.each{|record| yield record } }
        else
          self.find_in_batches_in_order(batch_size: batch_size).
            inject([]){|list, batch| list += batch.all }
        end
      end # find_each_in_order
      
      # emulate `each_slice` using find_in_batches_in_order
      def find_each_slice_in_order(slice_size, batch_size: 1000)
        slice_buffer = []
        
        self.find_in_batches_in_order(batch_size: batch_size).each do |batch|
          batch.each do |record|
            slice_buffer << record
            if slice_buffer.size == slice_size
              yield slice_buffer
              slice_buffer = []
            end
          end # each record
        end # each batch
        
        yield slice_buffer if slice_buffer.any?
      end # find_each_slice_in_order
    end
  end
end

ActiveRecord::Relation.send :include, CoreExt::ActiveRecord::Batches
