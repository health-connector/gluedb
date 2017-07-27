module ExternalEvents
  module EnrollmentEventNotificationFilters
    class RemoveSameActionsAndSelectSilent
      def filter(full_event_list)
        full_event_list.inject([]) do |acc, event|
          duplicate_found = acc.detect do |item|
            [event.hbx_enrollment_id, event.enrollment_action] == [item.hbx_enrollment_id, item.enrollment_action]
          end
          if duplicate_found
            # Favor the event marked as silent
            if (!duplicate_found.is_publishable?)
              event.drop_payload_duplicate!
              acc
            elsif (!event.is_publishable?)
              filtered_accs = acc.reject do |item|
                [event.hbx_enrollment_id, event.enrollment_action] == [item.hbx_enrollment_id, item.enrollment_action]
              end
              duplicate_found.drop_payload_duplicate!
              filtered_accs + [event]
            else
              event.drop_payload_duplicate!
              acc
            end
          else
            acc + [event]
          end
        end
      end
    end
  end
end
