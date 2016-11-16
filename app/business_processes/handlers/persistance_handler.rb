module Handlers
  class PersistanceHandler
    def initialize(app)
      @app = app
    end

    def call(context)
      update_database(context)
      @app.call(context)
    end

    protected

    def update_database(context)
    end
  end
end
