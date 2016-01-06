module Listeners
  class EnrollmentValidator < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.enrollment_validator"
    end

    def validate(delivery_info, properties, payload)
      if properties.reply_to.blank?
        add_error("Reply to is empty.")
      end
    end

    def on_message(delivery_info, properties, payload)
      event_key = delivery_info.routing_key
      qr_uri = properties.headers["qualifying_reason_uri"]
      reply_to = properties.reply_to
      body = payload

      uc_listener = Listeners::NewEnrollmentListener.new(
        {
          :qualifying_reason => qr_uri,
          :reply_to => reply_to
        },
        self)
      listener = NewEnrollment::PersonMappingListener.new(uc_listener)

      request = NewEnrollmentRequest.from_xml(payload)
      result = NewEnrollment.new.validate(request, listener) 
      if result
        listener.success
      else
        listener.fail
      end
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def handle_success(details, policy_ids, canceled_policies)
      channel.default_exchange.publish(
        "",
        {
          :routing_key => details[:reply_to],
          :headers => {
            :return_status => "200"
          }
        }
      )
    end

    def handle_failure(details, errors)
      channel.default_exchange.publish(
        JSON.dump(errors),
        {
          :routing_key => details[:reply_to],
          :headers => {
            :return_status => "422"
          }
        })
    end

    def self.run
      conn = AmqpConnectionProvider.start_connection
      chan = conn.create_channel
      chan.prefetch(1)
      q = chan.queue(self.queue_name, :durable => true)
      self.new(chan, q).subscribe(:block => true, :manual_ack => true)
    end
  end
end
