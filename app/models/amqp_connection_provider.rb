class AmqpConnectionProvider
  def self.start_connection
    bunny = Bunny.new(ExchangeInformation.amqp_uri, :heartbeat => 10)
    bunny.start
    bunny
  end
end
