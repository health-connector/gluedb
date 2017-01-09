module Handlers
  class EnrollmentEventEnrichHandler < ::Handlers::Base

    # Takes a 'bucket' of enrollment event notifications and transforms them
    # into a concrete set of enrollment actions.  We then invoke the step
    # after us once for each in that set.
    # [::ExternalEvents::EnrollmentEventNotification] -> [::EnrollmentAction::Base]
    def call(context)
      no_bogus_terms = discard_bogus_terms(enrollments)
      sorted_actions = no_bogus_terms.sort
    end

    def discard_bogus_terms(enrollments)
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
