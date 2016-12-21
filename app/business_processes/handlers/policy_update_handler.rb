module Handlers
  class PolicyUpdateHandler < Base
    def call(context)
      if context.terminations.any?
        context.terminations.each do |term|
          term.execute!
        end
      end
      if context.cancellations.any?
        context.cancellations.each do |term|
          term.execute!
        end
      end
      super(context)
    end
  end
end
