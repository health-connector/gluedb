module Handlers
  class PublisherHandler < Base

    def call(context)
      @app.call(context)
    end
  end
end
