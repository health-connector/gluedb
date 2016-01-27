class ImportBrokers
  def self.from_xml(xml)
    brokers = BrokerFactory.new.create_many_from_xml(xml)
    brokers.each do |b|
      Broker.find_or_create(b) unless b.npn.blank?
    end
  end

  def self.from_csv(csv)
    brokers = BrokerFactory.new.create_many_from_csv(csv)
    brokers.each do |b|
      Broker.find_or_create(b) unless b.npn.blank?
    end
  end
end
