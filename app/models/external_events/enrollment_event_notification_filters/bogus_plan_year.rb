module ExternalEvents
  module EnrollmentEventNotificationFilters
    class BogusPlanYear
      def filter(enrollments)
        _dropped, keep = enrollments.partition { |en| en.drop_if_bogus_plan_year! }
        _dropped = nil
        keep
      end
    end
  end
end
