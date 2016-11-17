# Put an Enrollment Event CV onto the bus after transforming
module Handlers
  class TransmitEdiForEvent < Base
    
    def initialize(app, enroll_type = :initial_enrollment)
      @app = app
      @enroll_type = enroll_type
    end

    # Context requires:
    # - enrollment_event_cv (Openhbx::Cv2::EnrollmentEvent)
    # - amqp_connection (A connection to an amqp service)
    # - raw_event_xml (a string containing the raw event xml)
    def call(context)
      action_xml = context.raw_event_xml
      edi_builder = EdiCodec::X12::BenefitEnrollment.new(action_xml)
      x12_xml = edi_builder.call.to_xml
      publish_to_bus(context.amqp_connection, context.enrollment_event_cv, x12_xml)
      @app.call(context)
    end

    def publish_to_bus(amqp_connection, enrollment_event_cv, x12_payload)
      ::Amqp::ConfirmedPublisher.with_confirmed_channel(amqp_connection) do |chan|
        ex = chan.default_exchange
        ex.publish(x12_payload, :routing_key => routing_key, :headers => {
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
      category_identifier = (@enroll_type == :initial_enrollment) ? "_C_E_" : "_C_M_"
      "834_" + transaction_id(enrollment_event_cv) + "_" + carrier_identifier + category_identifier + market_identifier + "_1.xml"
    end

    protected
    def extract_policy(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.enrollment.policy.value
    end

    def determine_market(enrollment_event_cv)
      shop_enrollment = Maybe.new(enrollment_event_cv).event.body.enrollment.policy.policy_enrollment.shop_market.value 
      shop_enrollment.nil? ? "individual" : "shop"
    end

    def routing_key
      (@enroll_type == :initial_enrollment) ? "hbx.enrollment_messages" : "hbx.maintenance_messages"
    end

    def transaction_id(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.transaction_id.strip.value
    end

    def shop_market?(enrollment_event_cv)
      determine_market(enrollment_event_cv) == "shop"
    end

    def extract_hios_id(policy_cv)
      return nil if policy_cv.policy_enrollment.plan.id.blank?
      policy_cv.policy_enrollment.plan.id.split("#").last
    end

    def extract_active_year(policy_cv)
      return nil if policy_cv.policy_enrollment.plan.blank?
      policy_cv.policy_enrollment.plan.active_year
    end
  end
end
