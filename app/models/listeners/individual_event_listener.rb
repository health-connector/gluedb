module Listeners
  class IndividualEventListener < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.individual_updated_listener"
    end

    def resource_event_broadcast(level, event_key, ind_id, r_code, body = "")
        event_body = (body.respond_to?(:to_s) ? body.to_s : body.inspect)
        broadcast_event({
          :routing_key => "#{level}.application.gluedb.individual_update_event_listener.#{event_key}",
          :headers => {
            :individual_id => ind_id,
            :return_status => r_code.to_s
          }
        },event_body)
    end

    def resource_error_broadcast(event_key, ind_id, r_code, body = "")
      resource_event_broadcast("error", event_key, ind_id, r_code, body)
    end

    def on_message(delivery_info, properties, body)
      m_headers = (properties.headers || {}).to_hash.stringify_keys
      individual_id = m_headers["individual_id"].to_s
      r_code, resource_or_body = ::RemoteResources::IndividualResource.retrieve(self, individual_id)
      case r_code.to_s
      when "200"
        resource_event_broadcast("info", "individual_created", individual_id, r_code, resource_or_body)
        channel.ack(delivery_info.delivery_tag, false)
      when "404"
        resource_error_broadcast("resource_not_found", individual_id, r_code)
        channel.ack(delivery_info.delivery_tag, false)
      when "503"
        resource_error_broadcast("resource_timeout", individual_id, r_code)
        channel.nack(delivery_info.delivery_tag, false, true)
      else
        resource_error_broadcast("unknown_error", individual_id, r_code, resource_or_body)
        channel.nack(delivery_info.delivery_tag, false, true)
      end
    end
  end
end
