module Publishers
  class TradingPartnerLegacyCv
    
    attr_reader :event_xml
    attr_reader :amqp_connection
    attr_reader :employer_id
    attr_reader :hbx_enrollment_id
    attr_reader :errors

    def initialize(amqp_c, e_xml, hbx_enrollment_id, employer_id)
      @amqp_connection = amqp_c
      @event_xml = e_xml
      @employer_id = employer_id
      @hbx_enrollment_id = employer_id
      @errors = ActiveModel::Errors.new(self)
    end

    def publish
      if (!employer_id.blank?)
        cv1 = EdiCodec::Cv1::Cv1Builder.new(event_xml)
        v1_xml = cv1.call.to_xml
        pubber = ::Services::NfpPublisher.new
        pubber.publish(true, "#{hbx_enrollment_id}.xml", v1_xml)
      end
      true
    end

    # Errors stuff for ActiveModel::Errors
    def read_attribute_for_validation(attr)
      send(attr)
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end
  end
end
