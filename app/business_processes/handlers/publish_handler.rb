module Handlers
  class PublishHandler < Base

    def call(context)
      super(context)
    end

    protected

    def notify_trading_partners(context)
      process_stack = Middleware::Builder.new do |b|
        b.use Handlers::TransmitNfpXmlHandler
        b.use Handlers::TransmitEdiForEvent
      end
      process_stack.call(context)
    end
  end
end
