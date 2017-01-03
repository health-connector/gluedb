module Handlers
  class EnrollmentEventReduceHandler < Base
    
    # call :: EnrollmentEventMessageBatch -> [EnrollmentEventMessageBatch]
    # We then do a reduce/expand which creates a list of EnrollmentEventMessageBatch objects.
    # We then invoke the step after us once for each new batch object.
    def call(context)
      reduced_list = perform_reduction(context.enrollment_event_messages)
      reduced_list.map do |element|
        new_context = duplicate_context(context, element)
#        begin
          super(new_context)
#        rescue
          # Add error information to duplicated context
#        end
      end
    end

    protected

    def duplicate_context(context, reduced_set)
      new_context = context.clone
      new_context.enrollment_event_messages = reduced_set
      new_context
    end

    def perform_reduction(event_list)
      event_list.combination(2).each do |a, b|
        if a.hash == b.hash
          if a.duplicates?(b)
            a.mark_for_drop!
            b.mark_for_drop!
          end
        end
      end
      dropped, free_of_dupes  = event_list.partition(&:drop_if_marked!)
      # GC hint
      dropped = nil
      free_of_dupes.group_by(&:bucket_id).values
    end
  end
end
