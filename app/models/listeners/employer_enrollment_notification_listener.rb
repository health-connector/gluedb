module Listeners
  class EmployerContactInformationEdiUpdateRequestHandler < Amqp::RetryClient
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.employer_contact_information_edi_update_request_handler"
    end

    def on_message(delivery_info, properties, body)
      m_headers = (properties.headers || {}).to_hash.stringify_keys
      employer_id = m_headers["employer_id"].to_s
      event_time = get_timestamp(properties)
      employer = Employer.where(hbx_id: employer_id).first
      en = Publishers::EmployerEnrollmentNotification.new(employer)
      en.process_enrollments_for_edi
      broadcast_event({
        :routing_key => "info.application.glue.employer_contact_information_edi_update_request_handler.request_processed",
        :headers => m_headers.merge({
          :return_status => "200"
        })
      })
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
      q.bind(event_topic_exchange, {:routing_key => "info.events.employer_edi.contact_information_updates_requested"})
    end

    def self.create_queues(chan)
      q = chan.queue(
        self.queue_name,
        {
          :durable => true,
          :arguments => {
            "x-dead-letter-exchange" => (self.queue_name + "-retry")
          }
        }
      )
      retry_q = chan.queue(
        (self.queue_name + "-retry"),
        {
          :durable => true,
          :arguments => {
            "x-dead-letter-exchange" => (self.queue_name + "-requeue"),
            "x-message-ttl" => 1000
          }
        }
      )
      retry_exchange = chan.fanout(
        (self.queue_name + "-retry")
      )
      requeue_exchange = chan.fanout(
        (self.queue_name + "-requeue")
      )
      retry_q.bind(retry_exchange, {:routing_key => ""})
      q.bind(requeue_exchange, {:routing_key => ""})
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
