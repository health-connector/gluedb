module TradingPartnerTransforms
  # Transforms an enrollment event CV into a trading partner payload using
  # the given EdiCodec builder (EdiCodec::X12::BenefitEnrollment or
  # EdiCodec::Cv1::Cv1Builder). File naming matches the legacy
  # script/transform_edi_files.rb output.
  class EdiFileTransformer
    include Handlers::EnrollmentEventXmlHelper

    def initialize(builder_class)
      @builder_class = builder_class
    end

    # Returns [file_name, payload], or nil when the event is not publishable.
    def transform(action_xml)
      enrollment_event_cv = enrollment_event_cv_for(action_xml)
      return nil unless is_publishable?(enrollment_event_cv)
      edi_builder = @builder_class.new(action_xml)
      payload = edi_builder.call.to_xml
      [determine_file_name(enrollment_event_cv), payload]
    end

    def find_carrier_abbreviation(enrollment_event_cv)
      policy_cv = extract_policy(enrollment_event_cv)
      found_plan = extract_plan(policy_cv)
      found_plan.carrier.abbrev.upcase
    end

    def determine_file_name(enrollment_event_cv)
      market_identifier = shop_market?(enrollment_event_cv) ? "S" : "I"
      carrier_identifier = find_carrier_abbreviation(enrollment_event_cv)
      category_identifier = is_initial?(enrollment_event_cv) ? "_C_E_" : "_C_M_"
      "834_" + transaction_id(enrollment_event_cv) + "_" + carrier_identifier + category_identifier + market_identifier + "_1.xml"
    end

    protected

    def is_publishable?(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.publishable?.value
    end

    def is_initial?(enrollment_event_cv)
      event_name = Maybe.new(enrollment_event_cv).event.body.enrollment.enrollment_type.strip.split("#").last.downcase.value
      (event_name == "initial")
    end

    def transaction_id(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.transaction_id.strip.value
    end

    def shop_market?(enrollment_event_cv)
      determine_market(enrollment_event_cv) == "shop"
    end
  end
end
