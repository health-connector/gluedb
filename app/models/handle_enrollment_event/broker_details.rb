module HandleEnrollmentEvent
  class BrokerDetails
    include Virtus.model

    attribute :npn, String

    def found_broker
      @found_broker ||= Broker.by_npn(npn).first
    end
  end
end
