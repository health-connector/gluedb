require 'base64'
require 'zlib'

module Listeners
  class PolicyIdListListener < ::Amqp::Client
    def on_message(delivery_info, properties, body, time_provider = Time)
      headers = (properties.headers || {})
      reply_to = properties.reply_to
      response_properties = {
        :timestamp => Time.now.to_i,
        :routing_key => reply_to,
        :headers => {
          :return_status => "200",
          :deflated_response => "true"
        }
      }

      pols = Policy.collection.raw_aggregate([
        {"$group" => {"_id" => "$eg_id"}},
        { "$sort" => {"_id" => 1}}
      ])

      policy_list = []

      pols.each do |pol|
        policy_list << pol["_id"]
      end

      buffer = StringIO.new
      gzw = Zlib::GzipWriter.new(buffer, Zlib::BEST_COMPRESSION)
      gzw.write(JSON.dump(policy_list))
      gzw.close
      buffer.rewind
      body_string = Base64.encode64(buffer.string)
      with_response_exchange do |rex|
        rex.publish(body_string, response_properties)
      end

      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.policy_id_list_listener"
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
