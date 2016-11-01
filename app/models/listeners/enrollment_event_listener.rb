module Listeners
  class EnrollmentEventListener < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.enrollment_event_listener"
    end

    def resource_event_broadcast(level, event_key, r_code, body = "")
        event_body = (body.respond_to?(:to_s) ? body.to_s : body.inspect)
        submit_time = 
        broadcast_event({
          :routing_key => "#{level}.application.gluedb.enrollment_event_listener.#{event_key}",
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
      individual_id = m_headers["individual_id"].to_s

      policy_cv = extract_policy_cv(body)
      workflow_arguments = {
        :amqp_connection => connection,
        :original_payload => body,
        :policy_cv => policy_cv,
        :processing_errors => HandlePolicyNotification::ProcessingErrors.new
      }

      result = HandlePolicyNotification::ProcessNotification.call(workflow_arguments)
      
      if result.fail?
        resource_error_broadcast("invalid_event", "522", {
          :errors => result.processing_errors.errors.to_hash,
          :event => body
        }.to_json)
        channel.ack(delivery_info.delivery_tag, false)
      else
        resource_event_broadcast("info", "event_processed", "200") 
        channel.ack(delivery_info.delivery_tag, false)
      end
    end
    
    def extract_policy_cv(payload)
      Openhbx::Cv2::Policy.parse(payload, single: true)
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
