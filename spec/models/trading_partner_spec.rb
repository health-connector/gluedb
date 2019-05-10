require 'rails_helper'

describe TradingPartner do
  subject { TradingPartner.new }

  describe "general requirements" do
    it "has expected fields" do
      expect(subject.fields.keys).to include("name")
      expect(subject.fields.keys).to include("inbound_enrollment_advice_enricher")
    end
  end

  describe "#inbound_enrollment_advice_enricher" do
    it "defaults to nothing" do
      expect(subject.inbound_enrollment_advice_enricher).to be nil
    end
  end
end
