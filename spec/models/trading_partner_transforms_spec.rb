require 'rails_helper'

describe TradingPartnerTransforms do
  describe ".enabled?" do
    around(:each) do |example|
      original = ENV['TRADING_PARTNER_TRANSFORMS_ENABLED']
      begin
        example.run
      ensure
        ENV['TRADING_PARTNER_TRANSFORMS_ENABLED'] = original
      end
    end

    it "is false when the variable is not set" do
      ENV.delete('TRADING_PARTNER_TRANSFORMS_ENABLED')
      expect(TradingPartnerTransforms.enabled?).to be_falsey
    end

    it "is false for any value other than true" do
      %w[false 0 yes enabled].each do |value|
        ENV['TRADING_PARTNER_TRANSFORMS_ENABLED'] = value
        expect(TradingPartnerTransforms.enabled?).to be_falsey
      end
    end

    it "is true for true, ignoring case and surrounding whitespace" do
      ["true", "TRUE", " True "].each do |value|
        ENV['TRADING_PARTNER_TRANSFORMS_ENABLED'] = value
        expect(TradingPartnerTransforms.enabled?).to be_truthy
      end
    end
  end
end
