module Protocols
  module Amqp
    class EventClient
      def initialize(chan, ev_resource)
        @channel = chan
        @resource = ev_resource
        event_exchange_spec = ::Protocols::Amqp::Settings.event_exchange(resource)
        @exchange = @channel.send(*event_exchange_spec)
      end

      def publish(resource_action, message)
        event_key = ::Protocols::Amqp::Settings.event_key(@resource, resource_action)
        @exchange.publish(
          message,
          :durable => true,
          :routing_key => event_key
        )
        @channel.wait_for_confirms || raise(::Amqp::PublishConfirmationError.new("Failed to publish event"))
      end
    end
  end
end
