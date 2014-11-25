module Listeners
  class EdiQueueListener < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.edi_ops"
    end

    def on_message(delivery_info, properties, payload)
      event_key = delivery_info.routing_key
      enrollment_group_uri = properties.headers["enrollment_group_uri"]
      qualifying_reason_uri = properties.headers["qualifying_reason_uri"]
      submitted_timestamp = properties.headers["submitted_timestamp"]
      event_name = properties.headers["event_name"]
      return_status = properties.headers["return_status"]
      EdiOpsTransaction.create!({
        :event_key => event_key,
        :event_name => event_name,
        :qualifying_reason_uri => qualifying_reason_uri,
        :submitted_timestamp => submitted_timestamp,
        :enrollment_group_uri => enrollment_group_uri,
        :return_status => properties.headers["return_status"],
        :errors => payload,
        :status => "new"
      })
      channel.acknowledge(delivery_info.delivery_tag, false) 
    end

    def error?(delivery_info)
      "enrollment.error" == delivery_info.routing_key 
    end

    def self.run
      conn = Bunny.new(ExchangeInformation.amqp_uri)
      conn.start
      chan = conn.create_channel
      chan.prefetch(1)
      q = chan.queue(self.queue_name, :durable => true)
      self.new(chan, q).subscribe(:block => true, :manual_ack => true)
    end
  end
end
