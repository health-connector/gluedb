module Handlers
  class EnrollmentEventPersistHandler < ::Handlers::Base

    # Handle the persistence operations for an enrollment action,
    # updating the objects in glue accordingly
    # ::EnrollmentAction::Base -> ::EnrollmentAction::Base
    def call(context)
      begin
        if context.persist
          super(context)
        else
          context.persist_failed!(context.errors.to_hash)
        end
      rescue NotImplementedError => e
        context.drop_not_yet_implemented!
      end
    end
  end
end
