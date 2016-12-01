module Listeners
  class EnrollQueryResultHandler < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.gluedb.enrollment_query_result_handler"
    end

    def resource_event_broadcast(level, event_key, r_code, body = "", other_headers = {})
        event_body = (body.respond_to?(:to_s) ? body.to_s : body.inspect)
        broadcast_event({
          :routing_key => "#{level}.application.gluedb.enroll_query_result_handler.#{event_key}",
          :headers => other_headers.merge({
            :return_status => r_code.to_s,
            :submitted_timestamp => Time.now
          })
        },event_body)
    end

    def resource_error_broadcast(event_key, r_code, body = "", other_headers = {})
      resource_event_broadcast("error", event_key, r_code, body, other_headers)
    end

    def process_retrieved_resource(delivery_info, hbx_enrollment_id, r_code, enrollment_event_resource, m_headers, enrollment_action)
      begin
        new_body = enrollment_event_resource.transform_action_to(enrollment_action)
        ::Amqp::ConfirmedPublisher.with_confirmed_channel(connection) do |chan|
          dex = chan.default_exchange
          dex.publish(
            new_body,
            {
              :routing_key => ::Listeners::EnrollmentEventHandler.queue_name
            }
          )
        end
        resource_event_broadcast("info", "completed", "200", new_body, m_headers)
      rescue Exception => e
        resource_error_broadcast(
          "action_transformation_failed",
          "500",
          enrollment_event_resource,
          m_headers.merge({
            :error_kind => e.class.name.to_s,
            :error_message => e.message
          })
        )
      end
      channel.ack(delivery_info.delivery_tag, false)
    end

    def on_message(delivery_info, properties, body)
      m_headers = (properties.headers || {}).to_hash.stringify_keys
      hbx_enrollment_id = m_headers["hbx_enrollment_id"].to_s
      enrollment_action = m_headers["enrollment_action_uri"].to_s
      r_code, resource_or_body = ::RemoteResources::EnrollmentEventResource.retrieve(self, hbx_enrollment_id)
      case r_code.to_s
      when "200"
        process_retrieved_resource(delivery_info, hbx_enrollment_id, r_code, resource_or_body, m_headers, enrollment_action)
      when "404"
        resource_error_broadcast("resource_not_found", hbx_enrollment_id, r_code, m_headers)
        channel.ack(delivery_info.delivery_tag, false)
      when "503"
        resource_error_broadcast("resource_timeout", hbx_enrollment_id, r_code, m_headers, m_headers)
        channel.reject(delivery_info.delivery_tag, true)
      else
        resource_error_broadcast("unknown_error", hbx_enrollment_id, r_code, resource_or_body, m_headers)
        channel.ack(delivery_info.delivery_tag, false)
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
