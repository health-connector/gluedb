module BusinessProcesses
  class EnrollmentEventReducer
    include Enumerable

    def initialize(messages)
      @items = messages
    end

    def buckets
      @buckets ||= begin
                     @items.combination(2).each do |a, b|
                       if a.hash == b.hash
                         if a.duplicates?(b)
                           a.mark_for_drop!
                           b.mark_for_drop!
                         end
                       end
                     end
                     [dropped, free_of_dupes]  = @items.partition(&:drop_if_marked!)
                     # GC hint
                     dropped = nil
                     free_of_dupes.group_by(&:bucket_id).values
                   end
    end
  end
end
