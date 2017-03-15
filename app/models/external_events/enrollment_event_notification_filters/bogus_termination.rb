module ExternalEvents
  module EnrollmentEventNotificationFilters
    class BogusTermination
      def filter(enrollments)
        aw = ArrayWindow.new(enrollments)
        aw.each do |items|
          current, before, after = items
          current.check_for_bogus_term_against(before + after)
        end
        _dropped, keep = enrollments.partition { |en| en.drop_if_bogus_term! }
        _dropped = nil
        keep
      end
    end
  end
end
