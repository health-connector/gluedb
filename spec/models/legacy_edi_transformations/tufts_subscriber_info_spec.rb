require "rails_helper"

describe LegacyEdiTransformations::TuftsSubscriberInfo, "given:
  - given a blank subscriber id
  - given a blank exchange assigned policy id
  - given a hios id
  - given a subscriber start
  - the policy does not exist
" do
  let(:subscriber_id) { nil }
  let(:eapi) { nil }
  let(:hios_id) { "A HIOS ID" }
  let(:subscriber_start) { "20180301" }

  subject do
    LegacyEdiTransformations::TuftsSubscriberInfo.new(
      subscriber_id,
      hios_id,
      eapi,
      subscriber_start
    )
  end

  it "finds nothing" do
    expect(subject.locate_policy_information).to eq nil
  end
end

describe LegacyEdiTransformations::TuftsSubscriberInfo, "given:
  - given a blank subscriber id
  - given an exchange assigned policy id
  - given a hios id
  - given a subscriber start
  - the policy does not exist
" do
  let(:subscriber_id) { nil }
  let(:eapi) { "AN EXCHANGE ASSIGNED POLICY ID" }
  let(:hios_id) { "A HIOS ID" }
  let(:subscriber_start) { "20180301" }

  subject do
    LegacyEdiTransformations::TuftsSubscriberInfo.new(
      subscriber_id,
      hios_id,
      eapi,
      subscriber_start
    )
  end

  it "finds nothing" do
    expect(subject.locate_policy_information).to eq nil
  end
end

describe LegacyEdiTransformations::TuftsSubscriberInfo, "given:
  - given a subscriber id
  - given an exchange assigned policy id
  - given a hios id
  - given a subscriber start
  - the policy does exist
" do

  let(:subscriber_id) { "A SUBSCRIBER ID" }
  let(:eapi) { nil }
  let(:hios_id) { "A HIOS ID" }
  let(:subscriber_start) { "20180301" }

  subject do
    LegacyEdiTransformations::TuftsSubscriberInfo.new(
      subscriber_id,
      hios_id,
      eapi,
      subscriber_start
    )
  end

  describe "finding a policy with no employer" do
    let(:eapi) { "AN EG ID" }

    let(:policy) do
      instance_double(
        Policy,
        :eg_id => eapi,
        :employer => nil
      )
    end

    before :each do
      allow(Policy).to receive(:where).with(
        {
          :eg_id => eapi
        }
      ).and_return([policy])
    end

    it "finds the policy id but no employer information" do
      expect(subject.locate_policy_information).to eq [eapi,nil,nil]
    end
  end

  describe "finding a policy with an employer" do
    let(:eapi) { "AN EG ID" }

    let(:policy) do
      instance_double(
        Policy,
        :eg_id => eapi,
        :employer => employer
      )
    end

    let(:eapi) { "AN EG ID" }
    let(:employer_name) { "AN EMPLOYER NAME" }
    let(:employer_fein) { "AN EMPLOYER FEIN" }

    let(:employer) do
      instance_double(
        Employer,
        :name => employer_name,
        :fein => employer_fein
      )
    end

    let(:policy) do
      instance_double(
        Policy,
        :eg_id => eapi,
        :employer => employer
      )
    end

    before :each do
      allow(Policy).to receive(:where).with(
        {
          :eg_id => eapi
        }
      ).and_return([policy])
    end

    it "finds the policy id and employer information" do
      expect(subject.locate_policy_information).to eq [eapi,employer_name,employer_fein]
    end
  end
end
