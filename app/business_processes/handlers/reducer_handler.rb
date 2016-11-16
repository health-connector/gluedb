module Handlers
  class ReducerHandler
    def initialize(app)
      @app = app
    end

    def call(context)
      reduced_list = perform_reduction(context.event_list)
      reduced_list.map do |element|
        @app.call(duplicate_context(context, element))
      end
    end

    protected

    def duplicate_context(context, reduced_set)
      new_context = OpenStruct.new
      context.each_pair do |k, v|
        if !(k.to_s == "event_list")
          context[k] = v
        end
      end
      new_context.event_list = reduced_set
      new_context
    end

    # Slug until we do actual reduction logic
    def perform_reduction(event_list)
      [event_list]
    end
  end
end
