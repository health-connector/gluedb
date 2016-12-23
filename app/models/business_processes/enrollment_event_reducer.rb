module BusinessProcesses
  class EnrollmentEventReducer
    include Enumerable

    def initialize
      @set_holder = Hash.new { |h,k| h[k] = Array.new }
    end

    def merge!(item)
      h_key = item.hash
      existing_sets = @set_holder[h_key]
      matches, no_match = existing_sets.partition { |s| s.duplicates?(item) }
      if matches.any?
        matches.each do |match|
          match.drop!
          # GC hint
          match.freeze
        end
        item.drop!
        # GC hint
        match.freeze
        @set_holder[h_key] = no_match + [item]
      else
        @set_holder[h_key] = no_match + [item]
      end
      self
    end

    def each
      @set_holder.values.each do |val|
        yield val
      end
    end
  end
end
