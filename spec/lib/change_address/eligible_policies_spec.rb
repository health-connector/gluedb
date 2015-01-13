require 'rails_helper'
describe ChangeAddress::EligiblePolicies do
  subject { ChangeAddress::EligiblePolicies.for_person(person) }
  let(:person) { double(policies: policies) }
  let(:currently_active_policy) { double(currently_active?: true, future_active?: false, policy_start: 1, policy_end: 2, coverage_type: health_coverage) }
  let(:future_active_policy) { double(currently_active?: false, future_active?: true, policy_start: 3, policy_end: nil, coverage_type: health_coverage) }
  let(:never_active_policy) { double(currently_active?: false, future_active?: false) }
  let(:policies) { [currently_active_policy, future_active_policy, never_active_policy] }
  let(:health_coverage) { "health" }
  let(:dental_coverage) { "dental" }

  it "provides the eligible policies for a person" do
    expect(subject).not_to be_nil
  end

  it "should not be empty" do
    expect(subject).not_to be_empty
  end

  it "should not include the currently active policy" do
    expect(subject.map { |pol| pol }).not_to include(currently_active_policy)

  end

  it "should include policies that will be active" do
    expect(subject.map { |pol| pol }).to include(future_active_policy)
  end

  it "should not include policies which are never active" do
    expect(subject.map { |pol| pol }).not_to include(never_active_policy)
  end

  context "with two overlapping future active policies, one health, one dental" do
    let(:future_active_policy) { double(currently_active?: false, future_active?: true, policy_start: 1, policy_end: nil, coverage_type: dental_coverage) }
    let(:other_future_policy) { double(currently_active?: false, future_active?: true, policy_start: 2, policy_end: nil, coverage_type: health_coverage) }
    let(:policies) { [future_active_policy, other_future_policy] }

    it "should not have too many active policies" do
      expect(subject.too_many_active_policies?).to be_false
    end

    it "should not have too many dental policies" do
      expect(subject.too_many_dental_policies?).to be_false
    end
  end

  context "with two future active policies which overlap and are both health" do
    let(:future_active_policy) { double(currently_active?: false, future_active?: true, policy_start: 1, policy_end: nil, coverage_type: health_coverage) }
    let(:other_future_policy) { double(currently_active?: false, future_active?: true, policy_start: 2, policy_end: nil, coverage_type: health_coverage) }
    let(:policies) { [future_active_policy, other_future_policy] }

    before :each do
      allow(future_active_policy).to receive(:coverage_period).and_return((1..5))
      allow(other_future_policy).to receive(:coverage_period).and_return((2..4))
    end

    it "should have too many active policies" do
      expect(subject.too_many_active_policies?).to be_true
    end

    it "should have too many health policies" do
      expect(subject.too_many_health_policies?).to be_true
    end
  end

  context "with a currently active policy that overlaps with a future active policy and are both dental" do
    let(:future_active_policy) { double(currently_active?: false, future_active?: true, policy_start: 2, policy_end: nil, coverage_type: dental_coverage) }
    let(:currently_active_policy) { double(currently_active?: true, future_active?: false, policy_start: 1, policy_end: 3, coverage_type: dental_coverage) }
    let(:policies) { [future_active_policy, currently_active_policy] }

    before :each do
      allow(future_active_policy).to receive(:coverage_period).and_return((2..4))
      allow(currently_active_policy).to receive(:coverage_period).and_return((1..3))
    end

    it "should have too many active policies" do
      expect(subject.too_many_active_policies?).to be_true
    end

    it "should have too many dental policies" do
      expect(subject.too_many_dental_policies?).to be_true
    end
  end

  context "with a currently active policy, a future active policy, both dental but don't overlap" do
    let(:future_active_policy) { double(currently_active?: false, future_active?: true, policy_start: 3, policy_end: nil, coverage_type: dental_coverage) }
    let(:currently_active_policy) { double(currently_active?: true, future_active?: false, policy_start: 1, policy_end: 3, coverage_type: dental_coverage) }
    let(:policies) { [future_active_policy, currently_active_policy] }

    before :each do
      allow(future_active_policy).to receive(:coverage_period).and_return((3..4))
      allow(currently_active_policy).to receive(:coverage_period).and_return((1..2))
    end

    it "should not have too many active policies" do
      expect(subject.too_many_active_policies?).to be_false
    end

    it "should not have too many dental policies" do
      expect(subject.too_many_dental_policies?).to be_false
    end
  end

end
