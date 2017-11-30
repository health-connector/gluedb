module ExternalEvents
  module EnrollmentEventNotificationFilters
    class AlreadyProcessedTermination
      def filter(enrollments)
        enrollments.reject do |en|
          en.drop_if_already_processed_termination!
        end
      end
    end
  end
end
