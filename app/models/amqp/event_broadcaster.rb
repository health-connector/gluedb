module Amqp
  class EventBroadcaster
    def initialize(conn)
      @connection = conn
    end

    def broadcast(props, payload)
      publish_props = props.dup
      publish_props.symbolize_keys!
      chan = @connection.create_channel
      begin
        out_ex = chan.fanout(ExchangeInformation.event_publish_exchange, :durable => true)
        if !(props.has_key?("timestamp") || props.has_key?(:timestamp))
          publish_props[:timestamp] = Time.now.to_i
        end
        add_workflow_id_if_missing(publish_props)
        chan.confirm_select
        out_ex.publish(payload, publish_props)
        chan.wait_for_confirms
      ensure
        chan.close
      end
    end

    def add_workflow_id_if_missing(message_props_hash)
      if message_props_hash.has_key?(:headers)
        headers = message_props_hash[:headers]
        if (!headers.has_key?("workflow_id")) && (!headers.has_key?(:workflow_id))
          message_props_hash[:headers]["workflow_id"] = SecureRandom.uuid.gsub("-","")
        end
      else
        message_props_hash[:headers] = { "workflow_id" => SecureRandom.uuid.gsub("-","") }
      end
    end

    def close
      @connection.close
    end

    def self.__get_local
      Thread.current[:__local_amqp_event_broadcaster_instance]
    end

    def self.with_broadcaster
      instance = __get_local
      if instance
        yield instance
      else
        new_instance = self.new(AmqpConnectionProvider.start_connection)
        yield new_instance
        new_instance.close
      end
    end

    def self.cache_local_instance
      existing_instance = __get_local
      raise ThreadError.new("Already using local instance scope for event broadcaster") if existing_instance
      new_instance = self.new(AmqpConnectionProvider.start_connection)
      Thread.current[:__local_amqp_event_broadcaster_instance] = new_instance
      yield
      Thread.current[:__local_amqp_event_broadcaster_instance] = nil
      new_instance.close
    end
  end
end
