module Listeners
  class BrokerUpdatedListener < ::Amqp::Client
    def on_message(delivery_info, properties, body)
      headers = (properties.headers || {})
      broker_id = headers.to_hash.stringify_keys['broker_id']
      brokers = Broker.by_npn(broker_id)
      if brokers.any?
        broker = brokers.first
        broker.update_attributes({})
      else
        Broker.create!({})
      end
      channel.acknowledge(delivery_info.delivery_tag, false)
    end
  end
end
