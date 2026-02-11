require 'timeout'
require 'thread'

module Amqp
  class Requestor
    def initialize(conn)
      @connection = conn
    end

    def request(properties, payload, timeout = 15)
      channel = @connection.create_channel
      p_channel = @connection.create_channel
      p_channel.confirm_select
      temp_queue = channel.queue("", :exclusive => true)
      channel.prefetch(1)
      request_exchange = p_channel.direct(ExchangeInformation.request_exchange, :durable => true)
      request_exchange.publish(payload, properties.dup.merge({ :reply_to => temp_queue.name, :persistent => true }))
      p_channel.wait_for_confirms || raise(::Amqp::PublishConfirmationError.new("Failed to publish request"))
      delivery_info, r_props, r_payload = [nil, nil, nil]
      begin
        Timeout::timeout(timeout) do
          temp_queue.subscribe({:manual_ack => true, :block => true}) do |di, prop, pay|
            delivery_info, r_props, r_payload = [di, prop, pay]
            channel.acknowledge(di.delivery_tag, false)
            throw :terminate, "success"
          end
        end
      ensure
        temp_queue.delete
        p_channel.close
        channel.close
      end
      [delivery_info, r_props, r_payload]
    end

    def self.default
      conn = AmqpConnectionProvider.start_connection
      self.new(conn)
    end
  end
end
