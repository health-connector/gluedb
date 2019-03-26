require 'rails_helper'

describe TradingPartner, :dbclean => :after_each do
  subject { TradingPartner.new }

  describe "general requirements" do
    it "has expected fields" do
      expect(subject.fields.keys).to include("name")
      expect(subject.fields.keys).to include("inbound_enrollment_advice_enricher")
    end
  end
end
