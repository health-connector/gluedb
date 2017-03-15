module ExternalEvents
  module EnrollmentEventNotificationFilters
    class AlreadyProcessedEvent
      def filter(enrollments)
        _dropped, keep = enrollments.partition { |en| en.drop_if_already_processed! }
        _dropped = nil
        keep
      end
    end
  end
end
