module Amqp
  class ConfirmedPublisher
    def self.with_confirmed_channel(connection)
      chan = connection.create_channel
      begin
        chan.confirm_select
        yield chan
        chan.wait_for_confirms || raise(::Amqp::PublishConfirmationError.new("Failed to publish message"))
      ensure
        chan.close
      end
    end
  end
end
