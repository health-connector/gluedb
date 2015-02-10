require 'csv'

module Generators::Reports  
  class MultiVersionAptcLookup

    attr_reader :monthly_aptcs

    def initialize(policy)
      @policy = policy
    end

    def morethan_two_aptcs?
      aptcs = @policy.versions.map(&:applied_aptc).map{ |x| x.to_f } + [ @policy.applied_aptc.to_f ]
      aptcs.uniq.size > 2
    end

    def valid?
      return false if times_changed > 1 || morethan_two_aptcs?
      true
    end

    def times_changed
      @monthly_aptcs = (1..12).inject([]) do |data, i|
        data << aptc_as_of(Date.new(2014, i, 1))
      end
      changed = 0
      monthly_aptcs.each_index do |i|
        break if monthly_aptcs[i+1].nil?
        if monthly_aptcs[i] == monthly_aptcs[i+1]
          changed += 1
        end
      end
      changed
    end

    def validate_versions
      if @policy.versions.sort_by(&:updated_at).last.applied_aptc != @policy.applied_aptc
        raise 'versions inconsistent!!'
      end
    end

    def aptc_as_of(date)
      coverage_start = @policy.subscriber.coverage_start
      coverage_end = @policy.subscriber.coverage_end || Date.new(2014, 12, 31)

      return if coverage_start > date || coverage_end <= date
      aptc_amounts = @policy.versions.map(&:applied_aptc).map{ |amt| amt.to_f }

      if (aptc_amounts.uniq.size == 1) && (aptc_amounts[0] == @policy.applied_aptc)
        return @policy.applied_aptc
      end

      if relevant_versions(date).empty?
        next_versions(date).empty? ? '0.0' : next_valid_version(date).applied_aptc
      else
        relevant_versions(date).last.applied_aptc
      end
    end

    def next_valid_version(date)
      versions = next_versions(date)
      next_month = versions.first.updated_at.month
      versions.select{ |v| v.updated_at.month == next_month }.last 
    end

    def versions_including_policy
      @policy.versions + [ @policy ]
    end

    def next_versions(date)
      versions_including_policy.select { |v| v.updated_at.year == date.year && v.updated_at.month >= date.month }.sort_by(&:updated_at)
    end

    def relevant_versions(date)
      versions_including_policy.select { |v| v.updated_at.year == date.year && v.updated_at.month < date.month }.sort_by(&:updated_at)
    end
  end
end
