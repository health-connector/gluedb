module Listeners
  class EnrollmentEventHandler < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.enrollment_event_handler"
    end

    def resource_event_broadcast(level, event_key, r_code, body = "")
        event_body = (body.respond_to?(:to_s) ? body.to_s : body.inspect)
        submit_time = 
        broadcast_event({
          :routing_key => "#{level}.application.gluedb.enrollment_event_handler.#{event_key}",
          :headers => {
            :return_status => r_code.to_s,
            :submitted_timestamp => Time.now
          }
        },event_body)
    end

    def resource_error_broadcast(event_key, r_code, body = "")
      resource_event_broadcast("error", event_key, r_code, body)
    end

    def on_message(delivery_info, properties, body)
      m_headers = (properties.headers || {}).to_hash.stringify_keys

      workflow_arguments = BusinessProcesses::EnrollmentEventContext.new
      workflow_arguments.amqp_connection = connection
      workflow_arguments.event_list = [body]

      results = EnrollmentEventClient.new.call(workflow_arguments)

      results.flatten.each do |res|
        if res.errors.has_errors?
          resource_error_broadcast("invalid_event", "522", {
            :errors => res.errors.errors.to_hash,
            :event => res.raw_event_xml
          }.to_json)
          channel.ack(delivery_info.delivery_tag, false)
        else
          resource_event_broadcast("info", "event_processed", "200", res.raw_event_xml) 
          channel.ack(delivery_info.delivery_tag, false)
        end
      end
    end

    def self.run
      conn = AmqpConnectionProvider.start_connection
      chan = conn.create_channel
      chan.prefetch(1)
      q = chan.queue(self.queue_name, :durable => true)
      self.new(chan, q).subscribe(:block => true, :manual_ack => true)
      conn.close
    end
  end
end
