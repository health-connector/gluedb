module HandlePolicyNotification
  # Transmit the policy operation for the 'main' policy.
  class EmitPrimaryEventOperation
    include Interactor

    # Context requires:
    # - raw_policy_xml (a Nokogiri node representing the original received policy node)
    # - primary_policy_action (a HandlePolicyNotification::PolicyAction)
    # - amqp_connection (A connection to an amqp service)
    def call
      action_xml = ApplicationController.new.render_to_string({
        :template => "edi_codec_events/enrollment_event",
        :format => :xml,
        :locals => {:enrollment_event => context.primary_policy_action, :raw_policy_xml => context.raw_policy_xml}
      })
      puts action_xml
      edi_builder = EdiCodec::X12::BenefitEnrollment.new(action_xml)
      x12_xml = edi_builder.call.to_xml
      puts x12_xml
      publish_to_bus(x12_xml)
    end

    def publish_to_bus(x12_payload)
      ::Amqp::ConfirmedPublisher.with_confirmed_channel(context.amqp_connection) do |chan|
         ex = chan.default_exchange
         ex.publish(x12_payload, :routing_key => determine_routing_key(context.primary_policy_action), :headers => {
           "market" => context.primary_policy_action.policy_details.market,
           "file_name" => determine_file_name(context.primary_policy_action)
         })
      end
    end

    def determine_file_name(policy_action)
      market_identifier = (policy_action.policy_details.market == "shop") ? "S" : "I"
      action_identifier = (policy_action.action == "initial") ? "C_E_" : "C_M_"
      carrier_identifier = policy_action.plan_details.found_plan.carrier.abbrev.upcase
      "834_" + policy_action.transaction_id + "_" + carrier_identifier + "_" + action_identifier + market_identifier + "_1.xml"
    end

    def determine_routing_key(policy_action)
      (policy_action.action == "initial") ? "hbx.enrollment_messages" : "hbx.maintenance_messages"
    end
  end
end
