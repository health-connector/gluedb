module Handlers
  class PublisherHandler
    def initialize(app)
      @app = app
    end

    def call(context)
      @app.call(context)
    end
  end
end
