module Amqp
  class EventBroadcaster
    def initialize(conn)
      @connection = conn
    end

    def broadcast(props, payload)
      publish_props = props.dup
      chan = @connection.create_channel
      begin
        chan.confirm_select
        out_ex = chan.fanout(ExchangeInformation.event_publish_exchange, :durable => true)
        if !(props.has_key?("timestamp") || props.has_key?(:timestamp))
          publish_props["timestamp"] = Time.now.to_i
        end
        out_ex.publish(payload, publish_props)
        chan.wait_for_confirms
      ensure
        chan.close
      end
    end
  end
end
