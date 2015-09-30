class ChannelProvider
  def self.with_channel
    bunny = Bunny.new(ExchangeInformation.amqp_uri, :heartbeat => 10)
    bunny.start
    chan = bunny.create_channel
    yield chan
    bunny.stop
  end
end
