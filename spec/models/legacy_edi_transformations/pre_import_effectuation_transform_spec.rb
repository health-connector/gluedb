require "rails_helper"

module LegacyEdiTransformationsTestDoubles
  class TransformDouble
  end
end

describe LegacyEdiTransformations::PreImportEffectuationTransform, "#select_transform" do
  describe "given a non-effectuation transmission" do

    let(:csv_row) do
      {
        "TRANSTYPE" => "TA1"
      }
    end

    subject { LegacyEdiTransformations::PreImportEffectuationTransform.new }

    it "selects no transformation" do
      expect(subject.select_transform(csv_row)).to eq nil
    end
  end

  describe "given an effectuation transmission but no matching trading profiles" do

    let(:csv_row) do
      {
        "TRANSTYPE" => "effectuation",
        "PARTNER" => "Name THPP_SHP"
      }
    end

    let(:trading_profile) do
      instance_double(
        TradingProfile,
        :profile_name => "GHMSI_SHP"
      )
    end

    let(:trading_partner) do
      instance_double(
        TradingPartner,
        :trading_profiles => [trading_profile],
        :inbound_enrollment_advice_enricher => "::LegacyEdiTransformationsTestDoubles::TransformDouble"
      )
    end

    before :each do
      allow(TradingPartner).to receive(:all).and_return([trading_partner])
    end

    subject { LegacyEdiTransformations::PreImportEffectuationTransform.new }

    it "selects no transformation" do
      expect(subject.select_transform(csv_row)).to eq nil
    end
  end

  describe "given an effectuation transmission and a matching profile" do

    let(:csv_row) do
      {
        "TRANSTYPE" => "effectuation",
        "PARTNER" => "Name THPP_SHP"
      }
    end

    let(:trading_profile) do
      instance_double(
        TradingProfile,
        :profile_name => "THPP_SHP"
      )
    end

    let(:trading_partner) do
      instance_double(
        TradingPartner,
        :trading_profiles => [trading_profile],
        :inbound_enrollment_advice_enricher => "::LegacyEdiTransformationsTestDoubles::TransformDouble"
      )
    end

    let(:transform_instance) { double }

    before :each do
      allow(TradingPartner).to receive(:all).and_return([trading_partner])
      allow(::LegacyEdiTransformationsTestDoubles::TransformDouble).to receive(:new).and_return(transform_instance)
    end

    subject { LegacyEdiTransformations::PreImportEffectuationTransform.new }

    it "selects the correct transformation" do
      expect(subject.select_transform(csv_row)).to eq transform_instance
    end
  end
end

describe LegacyEdiTransformations::PreImportEffectuationTransform, "#apply" do
  describe "given a non-effectuation transmission" do

    let(:csv_row) do
      {
        "TRANSTYPE" => "TA1"
      }
    end

    subject { LegacyEdiTransformations::PreImportEffectuationTransform.new }

    it "changes nothing" do
      expect(subject.apply(csv_row)).to eq csv_row
    end
  end

  describe "given an effectuation transmission but no matching trading profiles" do

    let(:csv_row) do
      {
        "TRANSTYPE" => "effectuation",
        "PARTNER" => "Name THPP_SHP"
      }
    end

    let(:trading_profile) do
      instance_double(
        TradingProfile,
        :profile_name => "GHMSI_SHP"
      )
    end

    let(:trading_partner) do
      instance_double(
        TradingPartner,
        :trading_profiles => [trading_profile],
        :inbound_enrollment_advice_enricher => "::LegacyEdiTransformationsTestDoubles::TransformDouble"
      )
    end

    before :each do
      allow(TradingPartner).to receive(:all).and_return([trading_partner])
    end

    subject { LegacyEdiTransformations::PreImportEffectuationTransform.new }

    it "changes nothing" do
      expect(subject.apply(csv_row)).to eq csv_row
    end
  end

  describe "given an effectuation transmission and a matching profile" do

    let(:csv_row) do
      {
        "TRANSTYPE" => "effectuation",
        "PARTNER" => "Name THPP_SHP"
      }
    end

    let(:trading_profile) do
      instance_double(
        TradingProfile,
        :profile_name => "THPP_SHP"
      )
    end

    let(:trading_partner) do
      instance_double(
        TradingPartner,
        :trading_profiles => [trading_profile],
        :inbound_enrollment_advice_enricher => "::LegacyEdiTransformationsTestDoubles::TransformDouble"
      )
    end

    let(:transform_instance) { double }
    let(:transformed_row) { double }

    before :each do
      allow(TradingPartner).to receive(:all).and_return([trading_partner])
      allow(::LegacyEdiTransformationsTestDoubles::TransformDouble).to receive(:new).and_return(transform_instance)
      allow(transform_instance).to receive(:apply).with(csv_row).and_return(transformed_row)
    end

    subject { LegacyEdiTransformations::PreImportEffectuationTransform.new }

    it "transforms using the correct transformation" do
      expect(subject.apply(csv_row)).to eq transformed_row
    end
  end
end