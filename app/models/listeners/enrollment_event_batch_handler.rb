module Listeners
  class EnrollmentEventBatchHandler < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.enrollment_event_batch_handler"
    end

    def resource_event_broadcast(level, event_key, r_code, body = "", other_headers = {})
        event_body = (body.respond_to?(:to_s) ? body.to_s : body.inspect)
        broadcast_event({
          :routing_key => "#{level}.application.gluedb.enrollment_event_batch_handler.#{event_key}",
          :headers => other_headers.merge({
            :return_status => r_code.to_s,
            :submitted_timestamp => Time.now
          })
        },event_body)
    end

    def resource_error_broadcast(event_key, r_code, body = "", other_headers)
      resource_event_broadcast("error", event_key, r_code, body, other_headers)
    end

    def process
      events = []
      di, props, payload = queue.pop({:manual_ack => true})
      while (di != nil) do
        event_message = BusinessProcesses::EnrollmentEventMessage.new
        event_message.message_tag = di.delivery_tag
        event_message.amqp_response_channel = channel
        event_message.event_xml = payload 
        events << event_message
        di, props, payload = queue.pop({:manual_ack => true})
      end
      batch = BusinessProcesses::EnrollmentEventMessageBatch.new(events)
      results = EnrollmentEventProcessingClient.new.call(batch)
      results.flatten.each do |res|
        if res.errors.has_errors?
          resource_error_broadcast("invalid_event", "522", {
            :errors => res.errors.errors.to_hash,
            :event => res.event_xml
          }.to_json, {:hbx_enrollment_id => res.hbx_enrollment_id})
        else
          resource_event_broadcast("info", "event_processed", "200", res.event_xml, {:hbx_enrollment_id => res.hbx_enrollment_id}) 
        end
      end
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

    def self.create_bindings(chan, q)
      ec = ExchangeInformation
      event_topic_exchange_name = "#{ec.hbx_id}.#{ec.environment}.e.topic.events"
      event_topic_exchange = chan.topic(event_topic_exchange_name, {:durable => true})
      # Replace with correct bindings for enrollment events
      # q.bind(event_topic_exchange, {:routing_key => "info.events.employer.#"})
    end

    def self.configure!
      conn = AmqpConnectionProvider.start_connection
      chan = conn.create_channel
      q = create_queues(chan)
      create_bindings(chan, q)
      conn.close
    end

    def self.run
      conn = AmqpConnectionProvider.start_connection
      chan = conn.create_channel
      q = create_queues(chan)
      self.new(chan, q).process
      conn.close
    end
  end
end
