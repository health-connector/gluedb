module Handlers
  class EnrollmentEventPublishHandler < ::Handlers::Base

    # Handle the publishing operations for an enrollment action
    # ::EnrollmentAction::Base -> ::EnrollmentAction::Base
    def call(context)
      begin
        if context.persist
          context.flow_successful!
          super(context)
        else
          # Log publish failure, halt chain
        end
      rescue NotImplementedError => e
        context.drop_not_yet_implemented!
      end
    end
  end
end
