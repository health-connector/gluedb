module HandlePolicyNotification
  # Transmit the policy operation for the 'main' policy.
  class EmitPrimaryEventOperation
    include Interactor

    # Context requires:
    # - raw_policy_xml (a Nokogiri node representing the original received policy node)
    # - primary_policy_action (a HandlePolicyNotification::PolicyAction)
    def call
      action_xml = ApplicationController.new.render_to_string({
        :template => "edi_codec_events/enrollment_event",
        :format => :xml,
        :locals => {:enrollment_event => context.primary_policy_action}
      })
      edi_builder = EdiCodec::X12::EdiBuilder.new(action_xml)
      x12_xml = edi_builder.call.to_xml
      publish_to_bus(x12_xml)
    end

    def publish_to_bus(x12_payload)
      puts x12_payload
    end
  end
end
