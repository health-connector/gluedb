module ExternalEvents
  module EnrollmentEventNotificationFilters
    class BogusRenewalTermination
      def filter(enrollments)
        enrollments.each_cons(2) do |a, b|
          a.check_for_bogus_renewal_term_against(b)
        end
        _dropped, keep = enrollments.partition { |en| en.drop_if_bogus_renewal_term! }
        _dropped = nil
        keep
      end
    end
  end
end
