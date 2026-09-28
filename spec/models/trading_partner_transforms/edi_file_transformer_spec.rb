require 'rails_helper'

describe TradingPartnerTransforms::EdiFileTransformer, :dbclean => :after_each do

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

  # The enrollment_event partial looks up a real Person per enrollee by
  # m_id. FactoryGirl's :policy does not create one, so every policy used
  # to render a real CV needs this bridge, matching the existing pattern
  # in spec/data_migrations/transform_xmls_spec.rb.
  def bridge_person_for(policy)
    # A shop policy needs distinct relationship codes, the cv1 schema
    # rejects two members both marked self.
    policy.enrollees.each_with_index do |en, index|
      en.update_attributes!(:rel_code => "spouse") if index > 0 && en.rel_code == "self"
    end
    policy.enrollees.each do |en|
      person = FactoryGirl.create(:person)
      # :person's default members can coincidentally share an
      # hbx_member_id with this enrollee, since both sequences start
      # at 1. Clear them so authority_member unambiguously resolves
      # to the one member that actually matches this enrollee.
      person.members.destroy_all
      person.members.create!(:hbx_member_id => en.m_id, :gender => "female", :dob => Date.new(1980, 1, 1), :ssn => "123456789")
      person.update_attributes!(:authority_member_id => en.m_id)
    end
    policy.reload
  end

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
