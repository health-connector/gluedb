module Handlers
  class EnrollmentEventReduceHandler < Base
    
    # call :: [::ExternalEvents::EnrollmentEventNotification]-> [[::ExternalEvents::EnrollmentEventNotification]]
    # We split out and collate the events into buckets.  Then we call the step after us once for each bucket.
    def call(context)
      reduced_list = perform_reduction(context)
      reduced_list.map do |element|
#        begin
          super(element)
#        rescue
          # Add error information to duplicated context
#        end
      end
    end

    protected

    def perform_reduction(full_event_list)
      event_list = full_event_list.inject([]) do |acc, event|
        duplicate_found = acc.any? do |item|
          [event.hbx_enrollment_id, event.enrollment_action] == [item.hbx_enrollment_id, item.enrollment_action]
        end
        if duplicate_found 
          event.drop_payload_duplicate!
          acc
        else
          acc + [event]
        end
      end
      event_list.combination(2).each do |a, b|
        if a.hash == b.hash
          a.check_and_mark_duplication_against(b)
        end
      end
      dropped, free_of_dupes  = event_list.partition(&:drop_if_marked!)
      # GC hint
      dropped = nil
      free_of_dupes.group_by(&:bucket_id).values
    end
  end
end
