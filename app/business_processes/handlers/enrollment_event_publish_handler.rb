module Handlers
  class EnrollmentEventPublishHandler < ::Handlers::Base

    # Handle the publishing operations for an enrollment action
    # ::EnrollmentAction::Base -> ::EnrollmentAction::Base
    def call(context)
      begin
        publish_result, publish_errors = context.publish
        if publish_result
          context.flow_successful!
          super(context)
        else
          # Log publish failure, halt chain
          context.publish_failed!(publish_errors)
        end
      rescue NotImplementedError => e
        context.drop_not_yet_implemented!
      end
    end
  end
end
