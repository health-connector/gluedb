require 'rails_helper'

describe TradingPartnerTransforms::EdiFileTransformer, :dbclean => :after_each do
  include TradingPartnerTransformsSpecHelpers

  # hbx_carrier_id 20002 (BCBS) is one of the issuers the edi_codec gem
  # recognizes. Any other id fails the transform, see the negative
  # examples below.
  # The edi_codec gem revision pinned here only defines shop market
  # classes for BCBS health (no individual market equivalent), so every
  # policy in this spec is a shop policy.
  let(:carrier) { FactoryGirl.create(:carrier, :hbx_carrier_id => "20002", :abbrev => "BCBS") }
  let(:plan) { FactoryGirl.create(:plan, :carrier => carrier, :year => 2026, :coverage_type => "health") }
  let(:policy) { FactoryGirl.create(:shop_policy, :plan => plan, :composite_rating_tier => "urn:openhbx:terms:v1:composite_rating_tier#employee_only").tap { |p| bridge_person_for(p) } }
  let(:action_xml) { TradingPartnerTransforms::SourceXmlGenerator.new(policy, "initial").generate }

  describe "#transform with a real recognized carrier" do
    describe "X12" do
      subject { described_class.new(EdiCodec::X12::BenefitEnrollment) }

      it "returns a file name and a non blank payload" do
        file_name, payload = subject.transform(action_xml)
        expect(file_name).to match(/\A834_\d+_BCBS_C_E_S_1\.xml\z/)
        expect(payload).to be_a(String)
        expect(payload).not_to be_blank
      end
    end

    describe "CV1" do
      subject { described_class.new(EdiCodec::Cv1::Cv1Builder) }

      it "returns a file name and a well formed XML payload" do
        file_name, payload = subject.transform(action_xml)
        expect(file_name).to match(/\A834_\d+_BCBS_C_E_S_1\.xml\z/)
        expect { Nokogiri::XML(payload, &:strict) }.not_to raise_error
      end
    end

    describe "for a terminate_enrollment reason code" do
      let(:action_xml) { TradingPartnerTransforms::SourceXmlGenerator.new(policy, "terminate_enrollment").generate }
      subject { described_class.new(EdiCodec::X12::BenefitEnrollment) }

      it "uses the maintenance category in the file name" do
        file_name, _payload = subject.transform(action_xml)
        expect(file_name).to include("_C_M_")
      end
    end

  end

  describe "#transform when the event is not publishable" do
    let(:unpublishable_xml) do
      <<-XML
        <enrollment_event xmlns="http://openhbx.org/api/terms/1.0">
          <event>
            <body>
              <enrollment_event_body>
                <transaction_id>12345</transaction_id>
                <is_trading_partner_publishable>false</is_trading_partner_publishable>
              </enrollment_event_body>
            </body>
          </event>
        </enrollment_event>
      XML
    end
    subject { described_class.new(EdiCodec::X12::BenefitEnrollment) }

    it "returns nil instead of building a payload" do
      expect(subject.transform(unpublishable_xml)).to be_nil
    end
  end

  describe "#transform with a carrier the edi_codec gem does not recognize" do
    let(:carrier) { FactoryGirl.create(:carrier) }
    subject { described_class.new(EdiCodec::X12::BenefitEnrollment) }

    it "raises instead of silently producing a bad file" do
      expect { subject.transform(action_xml) }.to raise_error(StandardError)
    end
  end

  describe "#transform with malformed xml" do
    subject { described_class.new(EdiCodec::X12::BenefitEnrollment) }

    it "raises instead of returning a broken payload" do
      expect { subject.transform("not xml at all") }.to raise_error(StandardError)
    end
  end
end
