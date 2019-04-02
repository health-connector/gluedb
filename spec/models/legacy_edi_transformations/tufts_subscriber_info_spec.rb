require "rails_helper"

describe LegacyEdiTransformations::TuftsSubscriberInfo, "given:
  - given a blank subscriber id
  - given a carrier assigned policy id
  - given a hios id
  - given a subscriber start
" do
  let(:subscriber_id) { nil }
  let(:capi) { "A CARRIER ASSIGNED POLICY ID" }
  let(:hios_id) { "A HIOS ID" }
  let(:subscriber_start) { "20180301" }

  subject do
    LegacyEdiTransformations::TuftsSubscriberInfo.new(
      subscriber_id,
      hios_id,
      capi,
      subscriber_start
    )
  end

  it "finds nothing" do
    expect(subject.locate_policy_information).to eq nil
  end
end

describe LegacyEdiTransformations::TuftsSubscriberInfo, "given:
  - given a subscriber id
  - given a carrier assigned policy id
  - given a blank hios id
  - given a subscriber start
" do
  let(:subscriber_id) { "A SUBSCRIBER ID" }
  let(:capi) { "A CARRIER ASSIGNED POLICY ID" }
  let(:hios_id) { nil }
  let(:subscriber_start) { "20180301" }

  subject do
    LegacyEdiTransformations::TuftsSubscriberInfo.new(
      subscriber_id,
      hios_id,
      capi,
      subscriber_start
    )
  end

  it "finds nothing" do
    expect(subject.locate_policy_information).to eq nil
  end
end

describe LegacyEdiTransformations::TuftsSubscriberInfo, "given:
  - given a subscriber id
  - given a carrier assigned policy id
  - given a hios id
  - given a blank subscriber start
" do
  let(:subscriber_id) { "A SUBSCRIBER ID" }
  let(:capi) { "A CARRIER ASSIGNED POLICY ID" }
  let(:hios_id) { "A HIOS ID" }
  let(:subscriber_start) { nil }

  subject do
    LegacyEdiTransformations::TuftsSubscriberInfo.new(
      subscriber_id,
      hios_id,
      capi,
      subscriber_start
    )
  end

  it "finds nothing" do
    expect(subject.locate_policy_information).to eq nil
  end
end

describe LegacyEdiTransformations::TuftsSubscriberInfo, "given:
  - given a subscriber id
  - given a blank carrier assigned policy id
  - given a hios id
  - given a subscriber start
" do

  let(:subscriber_id) { "A SUBSCRIBER ID" }
  let(:capi) { nil }
  let(:hios_id) { "A HIOS ID" }
  let(:subscriber_start) { "20180301" }

  subject do
    LegacyEdiTransformations::TuftsSubscriberInfo.new(
      subscriber_id,
      hios_id,
      capi,
      subscriber_start
    )
  end

  let(:plan) do
    instance_double(
      Plan,
      :id => plan_id
    )
  end

  let(:plan_id) { "A PLAN ID" }

  before :each do
    allow(Plan).to receive(:where).with(
      {:hios_id => hios_id}
    ).and_return(plan_results)
  end

  describe "which has no matching plans" do
    let(:plan_results) { [] }

    it "finds nothing" do
      expect(subject.locate_policy_information).to eq nil
    end
  end

  describe "finding a policy with no employer" do
    let(:plan_results) { [plan] }

    let(:policy_id) { "AN EG ID" }

    let(:enrollee) do
      instance_double(
        Enrollee,
        :m_id => subscriber_id,
        :coverage_start => Date.new(2018, 3, 1),
        :subscriber? => true
      )
    end

    let(:policy) do
      instance_double(
        Policy,
        :eg_id => policy_id,
        :employer => nil,
        :enrollees => [enrollee]
      )
    end

    before :each do
      allow(Policy).to receive(:where).with(
        {
          :plan_id => {"$in" => [plan_id]},
          "enrollees.m_id" => subscriber_id
        }
      ).and_return([policy])
    end

    it "finds the policy id but no employer information" do
      expect(subject.locate_policy_information).to eq [policy_id,nil,nil]
    end
  end

  describe "finding a policy with an employer" do
    let(:plan_results) { [plan] }

    let(:policy_id) { "AN EG ID" }
    let(:employer_name) { "AN EMPLOYER NAME" }
    let(:employer_fein) { "AN EMPLOYER FEIN" }

    let(:enrollee) do
      instance_double(
        Enrollee,
        :m_id => subscriber_id,
        :coverage_start => Date.new(2018, 3, 1),
        :subscriber? => true
      )
    end

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
        :eg_id => policy_id,
        :employer => employer,
        :enrollees => [enrollee]
      )
    end

    before :each do
      allow(Policy).to receive(:where).with(
        {
          :plan_id => {"$in" => [plan_id]},
          "enrollees.m_id" => subscriber_id
        }
      ).and_return([policy])
    end

    it "finds the policy id and employer information" do
      expect(subject.locate_policy_information).to eq [policy_id,employer_name,employer_fein]
    end
  end
end