class ChannelProvider
  def self.with_channel
    bunny = AmqpConnectionProvider.start_connection
    chan = bunny.create_channel
    yield chan
    bunny.stop
  end
end
