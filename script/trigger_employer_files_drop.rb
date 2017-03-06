ec = ExchangeInformation
event_topic_exchange_name = "#{ec.hbx_id}.#{ec.environment}.e.topic.events"
event_key = "info.events.trading_partner.employer_digest.requested"
conn = AmqpConnectionProvider.start_connection
Amqp::ConfirmedPublisher.with_confirmed_channel(conn) do |chan|
  event_topic_exchange_name = "#{ec.hbx_id}.#{ec.environment}.e.topic.events"
  event_topic_exchange = chan.topic(event_topic_exchange_name, {:durable => true})
  event_topic_exchange.publish("", {
    routing_key: event_key
  })
end
conn.close
