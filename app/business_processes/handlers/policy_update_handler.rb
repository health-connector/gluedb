module Handlers
  class PolicyUpdateHandler < Base
    def call(context)
      if context.terminations.any?
        context.terminations.each do |term|
          term.execute!
        end
      end
      @app.call(context)
    end
  end
end
