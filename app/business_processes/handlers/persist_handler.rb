module Handlers
  class PersistHandler < Base

    def call(context)
      update_database(context)
      super(context)
    end

    protected

    def update_database(context)
      process_stack = Middleware::Builder.new do |b|
        b.use Handlers::MemberPersistHandler
        b.use Handlers::PolicyPersistHandler
      end
      process_stack.call(context)
    end
  end
end
