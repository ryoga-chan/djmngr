module CoreExt::Integer::Utils
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def hamming_distance(a, b, signed: false)
      if signed
        a = [a].pack('q').unpack('Q').first
        b = [b].pack('q').unpack('Q').first
      end

      (a ^ b).to_s(2).count('1')
    end
  end # ClassMethods

  def hamming_distance_from(other, signed: false) = self.class.hamming_distance(self, other, signed)
end

Integer.send :include, CoreExt::Integer::Utils
