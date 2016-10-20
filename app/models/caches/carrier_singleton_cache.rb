module Caches
  class CarrierSingletonCache
    include Singleton

    def initialize
      @carriers = Carrier.all.inject({}) do |accum, c|
        accum[c.id] = c
        accum
      end
    end

    def lookup(m_id)
      @carriers[m_id]
    end

    def self.lookup(c_id)
      self.instance.lookup(c_id)
    end
  end
end
