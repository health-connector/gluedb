module Handlers
  class PublishHandler < Base

    def call(context)
      @app.call(context)
    end
  end
end
