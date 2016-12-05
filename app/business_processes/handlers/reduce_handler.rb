module Handlers
  class ReduceHandler < Base
    def call(context)
      reduced_list = perform_reduction(context.event_list)
      reduced_list.map do |element|
        new_context = duplicate_context(context, element)
#        begin
          super(duplicate_context(context, element))
#        rescue
          # Add error information to duplicated context
#        end
      end
    end

    protected

    def duplicate_context(context, reduced_set)
      new_context = context.clone
      new_context.event_list = reduced_set
      new_context
    end

    # Slug until we do actual reduction logic
    def perform_reduction(event_list)
      [event_list]
    end
  end
end
