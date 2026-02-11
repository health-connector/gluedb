class ChannelProvider
  def self.with_channel
    bunny = AmqpConnectionProvider.start_connection
    chan = bunny.create_channel
    yield chan
    bunny.stop
  end

  def self.with_confirmed_channel
    bunny = AmqpConnectionProvider.start_connection
    chan = bunny.create_channel
    chan.confirm_select
    yield chan
    chan.wait_for_confirms || raise(::Amqp::PublishConfirmationError.new("Failed to publish message"))
    bunny.close
  end
end
