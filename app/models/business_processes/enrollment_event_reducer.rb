module BusinessProcesses
  class EnrollmentEventReducer
    class EnrollmentEventReductionSet
      def initialize(starting_item)
        @items = starting_item
      end

      def match?(item)
        false
      end

      def merge!(item)
        @items = @items + [item]
        self
      end

      def each
        @items.each do |item|
          yield item
        end
      end
    end

    include Enumerable

    def initialize
      @set_holder = Hash.new { |h,k| h[k] = Array.new }
    end

    def merge!(item)
      h_key = item.hash
      existing_sets = @set_holder[h_key]
      match, no_match = existing_sets.partition { |s| s.match?(item) }
      if match.empty?
        @set_holder[h_key] = existing_sets + [EnrollmentEventReductionSet.new(item)]
      else
        fm, *rest_m = match
        updated_match = fm.merge!(item)
        @set_holder[h_key] = [fm] + rest_m + no_match
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
