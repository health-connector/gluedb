module ExternalEvents
  module EnrollmentEventNotificationFilters
    class TerminationWithoutEnd
      def filter(enrollments)
        _dropped, keep = enrollments.partition { |en| en.drop_if_term_with_no_end! }
        _dropped = nil
        keep
      end
    end
  end
end
