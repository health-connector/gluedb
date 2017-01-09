module Handlers
  class EnrollmentEventEnrichHandler < ::Handlers::Base

    # Takes a 'bucket' of enrollment event notifications and transforms them
    # into a concrete set of enrollment actions.  We then invoke the step
    # after us once for each in that set.
    # [::ExternalEvents::EnrollmentEventNotification] -> [::EnrollmentAction::Base]
    def call(context)

    end
  end
end
