# Put an Enrollment Event CV onto the bus after transforming
module Publishers
  class TradingPartnerEdi
    include Handlers::EnrollmentEventXmlHelper

    attr_reader :event_xml
    attr_reader :error_message
    attr_reader :amqp_connection
    attr_reader :errors

    def initialize(amqp_c, e_xml)
      @amqp_connection = amqp_c
      @event_xml = e_xml
      @errors = ActiveModel::Errors.new(self)
    end

    def publish
      action_xml = event_xml
      enrollment_event_cv = enrollment_event_cv_for(action_xml)
      if is_publishable?(enrollment_event_cv)
        begin
          edi_builder = EdiCodec::X12::BenefitEnrollment.new(update_transaction_id(action_xml, update_bgn))
          x12_xml = edi_builder.call.to_xml
          publish_to_bus(amqp_connection, enrollment_event_cv, x12_xml)
        rescue Exception => e
          errors.add(:error_message, e.message)
          errors.add(:event_xml, event_xml)
          return false
        end
      end
      true
    end

    def publish_to_bus(amqp_connection, enrollment_event_cv, x12_payload)
      ::Amqp::ConfirmedPublisher.with_confirmed_channel(amqp_connection) do |chan|
        ex = chan.default_exchange
        ex.publish(x12_payload, :routing_key => routing_key(enrollment_event_cv), :headers => {
          "market" => determine_market(enrollment_event_cv),
          "file_name" => determine_file_name(enrollment_event_cv)
        })
      end
    end

    def find_carrier_abbreviation(enrollment_event_cv)
      policy_cv = extract_policy(enrollment_event_cv)
      hios_id = extract_hios_id(policy_cv)
      active_year = extract_active_year(policy_cv)
      found_plan = Plan.where(:hios_plan_id => hios_id, :year => active_year.to_i).first
      found_plan.carrier.abbrev.upcase
    end

    def determine_file_name(enrollment_event_cv)
      market_identifier = shop_market?(enrollment_event_cv) ? "S" : "I"
      carrier_identifier = find_carrier_abbreviation(enrollment_event_cv)
      category_identifier = is_initial?(enrollment_event_cv) ? "_C_E_" : "_C_M_"
      "834_" + transaction_id(enrollment_event_cv) + "_" + carrier_identifier + category_identifier + market_identifier + "_1.xml"
    end

    protected

    def new_transaction_id
      ran = Random.new
      current_time = Time.now.utc
      reference_number_base = current_time.strftime("%Y%m%d%H%M%S") + current_time.usec.to_s[0..2]
      reference_number_base + sprintf("%05i", ran.rand(65535))
    end

    def update_transaction_id(action_xml, change_bgn = false)
      return action_xml unless change_bgn
      new_id_for_bgn = new_transaction_id
      the_xml = Nokogiri::XML(action_xml)
      the_xml.xpath("//cv:enrollment/cv:transaction_id/cv:id", {:cv => "http://openhbx.org/api/terms/1.0"}).each do |node|
        node.content = new_id_for_bgn
      end
      the_xml.xpath("//cv:enrollment_event_body/cv:transaction_id", {:cv => "http://openhbx.org/api/terms/1.0"}).each do |node|
        node.content = new_id_for_bgn
      end
      the_xml.to_xml(:indent => 2)
    end

    def is_publishable?(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.publishable?.value
    end

    def is_initial?(enrollment_event_cv)
      event_name = Maybe.new(enrollment_event_cv).event.body.enrollment.enrollment_type.strip.split("#").last.downcase.value
      (event_name == "initial")
    end

    def routing_key(enrollment_event_cv)
      is_initial?(enrollment_event_cv) ? "hbx.enrollment_messages" : "hbx.maintenance_messages"
    end

    def transaction_id(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.transaction_id.strip.value
    end

    def shop_market?(enrollment_event_cv)
      determine_market(enrollment_event_cv) == "shop"
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
