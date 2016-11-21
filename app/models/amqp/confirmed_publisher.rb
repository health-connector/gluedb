module Amqp
  class ConfirmedPublisher
    def self.with_confirmed_channel(connection)
      chan = connection.create_channel
      begin
        chan.confirm_select
        yield chan
        chan.wait_for_confirms
      ensure
        chan.close
      end
    end
  end
end
