require 'rails_helper'

describe TradingPartnerTransforms::SourceXmlGenerator, :dbclean => :after_each do

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

  let(:policy) { FactoryGirl.create(:policy).tap { |p| bridge_person_for(p) } }

  describe "#file_name" do
    it "combines the policy eg_id and the reason code" do
      generator = described_class.new(policy, "initial")
      expect(generator.file_name).to eq "#{policy.eg_id}_initial.xml"
    end

    it "changes with the reason code" do
      generator = described_class.new(policy, "terminate_enrollment")
      expect(generator.file_name).to eq "#{policy.eg_id}_terminate_enrollment.xml"
    end
  end

  describe "#event_type" do
    it "builds the openhbx enrollment type uri from the reason code" do
      generator = described_class.new(policy, "reinstate_enrollment")
      expect(generator.event_type).to eq "urn:openhbx:terms:v1:enrollment#reinstate_enrollment"
    end
  end

  describe "#transaction_id" do
    it "is memoized across calls" do
      generator = described_class.new(policy, "initial")
      first = generator.transaction_id
      second = generator.transaction_id
      expect(first).to eq second
    end
  end

  describe "#generate" do
    let(:generator) { described_class.new(policy, "initial") }
    let(:xml) { Nokogiri::XML(generator.generate) }

    it "renders a real enrollment_event document" do
      expect(xml.root.name).to eq "enrollment_event"
    end

    it "embeds the reason code as the enrollment type" do
      type_node = xml.at_xpath("//*[local-name()='type']")
      expect(type_node.text).to eq "urn:openhbx:terms:v1:enrollment#initial"
    end

    it "embeds the policy eg_id" do
      expect(generator.generate).to include(policy.eg_id)
    end

    it "embeds the same transaction_id used in the header and the enrollment section" do
      tid = generator.transaction_id
      transaction_id_nodes = xml.xpath("//*[local-name()='transaction_id']")
      expect(transaction_id_nodes.map { |n| n.text.strip }).to all(eq tid)
    end

    it "marks the event as trading partner publishable" do
      node = xml.at_xpath("//*[local-name()='is_trading_partner_publishable']")
      expect(node.text).to eq "true"
    end

    describe "for an individual policy" do
      it "sets the market to individual" do
        market_node = xml.at_xpath("//*[local-name()='enrollment']/*[local-name()='market']")
        expect(market_node.text).to eq "urn:openhbx:terms:v1:aca_marketplace#individual"
      end
    end

    describe "for a shop policy" do
      let(:policy) { FactoryGirl.create(:shop_policy).tap { |p| bridge_person_for(p) } }

      it "sets the market to shop" do
        market_node = xml.at_xpath("//*[local-name()='enrollment']/*[local-name()='market']")
        expect(market_node.text).to eq "urn:openhbx:terms:v1:aca_marketplace#shop"
      end
    end
  end
end
