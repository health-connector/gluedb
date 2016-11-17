module Handlers
  class Base

    # Avoid coupling the sender of a request to its receiver by giving more than one object a chance to handle the request.
    # Chain the receiving objects and pass the request along the chain until an object handles it.
    # Launch-and-leave requests with a single processing pipeline that contains many possible handlers.
    # An object-oriented linked list with recursive traversal.

    def initialize(app)
      @app = app
    end

    def call(context)
      current_process_history = context.business_process_history || []
      context.business_process_history = current_process_history + [self.class.name]
      @app.call(context)
    end

    # TODO - Examine client chain to catch any requests that go unhandled
    # TODO - Reference the enterprise logger
    # TODO - Reference the EDI journaling model

  end
end
