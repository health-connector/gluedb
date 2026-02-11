class AmqpConnectionProvider
  def self.start_connection
    bunny = Bunny.new(ExchangeInformation.amqp_connection_settings)
    bunny.start
    bunny
  end

  def self.with_connection
    bunny = Bunny.new(ExchangeInformation.amqp_connection_settings)
    bunny.start
    yield bunny
    bunny.close
  end
end
