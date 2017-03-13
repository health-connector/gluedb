module Listeners
  class EmployerDigestDropListener < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.employer_digest_drop_listener"
    end

    def resource_event_broadcast(level, event_key, r_code, body = "", other_headers = {})
        event_body = (body.respond_to?(:to_s) ? body.to_s : body.inspect)
        broadcast_event({
          :routing_key => "#{level}.application.glue.employer_digest_drop_listener.#{event_key}",
          :headers => other_headers.merge({
            :return_status => r_code.to_s,
            :submitted_timestamp => Time.now
          })
        },event_body)
    end

    def resource_error_broadcast(event_key, r_code, body = "", other_headers = {})
      resource_event_broadcast("error", event_key, r_code, body, other_headers)
    end

    def on_message(delivery_info, properties, body)
      m_headers = (properties.headers || {}).to_hash.stringify_keys
      ec = ExchangeInformation
      time_boundry = Time.now
      EmployerEvent.with_digest_payloads(time_boundry) do |payload|
        Amqp::ConfirmedPublisher.with_confirmed_channel(connection) do |chan|
          ex = chan.fanout(ec.event_publish_exchange, {:durable => true})
          ex.publish(
            payload,
            {routing_key: "info.events.trading_partner.employer_digest.published"}
          )
        end
      end
      EmployerEvent.clear_before(time_boundry)
      channel.ack(delivery_info.delivery_tag, false)
    end

    def get_timestamp(msg_properties)
      message_ts = msg_properties.timestamp
      return Time.now if message_ts.blank?
      return Time.at(message_ts) if message_ts.kind_of?(Fixnum) || message_ts.kind_of?(Integer)
      message_ts 
    end

    def self.create_bindings(chan, q)
      ec = ExchangeInformation
      event_topic_exchange_name = "#{ec.hbx_id}.#{ec.environment}.e.topic.events"
      event_topic_exchange = chan.topic(event_topic_exchange_name, {:durable => true})
      q.bind(event_topic_exchange, {:routing_key => "info.events.trading_partner.employer_digest.requested"})
    end

    def self.create_queues(chan)
      q = chan.queue(
        self.queue_name,
        {
          :durable => true,
        }
      )
      q
    end

    def self.run
      Process.setproctitle("%s - %s" % [self.name , $$])
      conn = AmqpConnectionProvider.start_connection
      chan = conn.create_channel
      q = create_queues(chan)
      create_bindings(chan, q)
      chan.prefetch(1)
      self.new(chan, q).subscribe(:block => true, :manual_ack => true, :ack => true)
      conn.close
    end
  end
end
