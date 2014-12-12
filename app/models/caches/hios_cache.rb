module Caches
  class HiosCache

    def initialize
      @records = Plan.all.group_by(&:hios_plan_id)
      @records.default = []
    end

    def lookup(m_id)
      @records[m_id]
    end

    def self.allocate
      Thread.current[key_for_hios_plans] = self.new
    end

    def self.release
      Thread.current[key_for_hios_plans] = nil
    end

    def self.lookup(id_val, &def_block)
      repo = Thread.current[key_for_hios_plans]
      return(def_block.call) if repo.nil?
      repo.lookup(id_val)
    end

    def self.key_for_hios_plans
      "hios_id_plans_cache_repository"
    end

    def self.with_cache
      args.each do |kls|
        self.allocate
      end
      yield
      args.each do |kls|
        self.release
      end
    end
  end
end
