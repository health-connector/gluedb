require "rails_helper"

describe PolicyInteractions::InitialEnrollment do

  let(:new_policy) { instance_double("Policy", :coverage_period => (Date.new(2015,1,1)..Date.new(2015, 12,31)), :carrier_id => 5) }
  let(:existing_policies) { [] }

  describe "with no exising policies" do
    it "should qualify for initial enrollment" do
      expect(subject.qualifies?(existing_policies, new_policy)).to be_truthy
    end
  end

  describe "with a policy with an overlapping coverage period" do
    let(:overlapping_policy) { instance_double("Policy", :coverage_period => (Date.new(2015,2,1)..Date.new(2015, 10,31))) }
    let(:existing_policies) { [overlapping_policy] }

    it "should not qualify for initial enrollment" do
      expect(subject.qualifies?(existing_policies, new_policy)).to be_falsey
    end
  end

  describe "with a policy from a directly previous coverage period, which is terminated" do
    let(:previous_policy) { instance_double("Policy", :coverage_period => (Date.new(2014,1,1)..Date.new(2014, 12,31)), :terminated? => true) }
    let(:existing_policies) { [previous_policy] }
    it "should not qualify for initial enrollment" do
      expect(subject.qualifies?(existing_policies, new_policy)).to be_truthy
    end
  end

  describe "with a policy from a directly previous coverage period, which is not terminated" do
    let(:previous_policy) { instance_double("Policy", :coverage_period => (Date.new(2014,1,1)..Date.new(2014, 12,31)), :terminated? => false) }
    let(:existing_policies) { [previous_policy] }
    it "should not qualify for initial enrollment" do
      expect(subject.qualifies?(existing_policies, new_policy)).to be_falsey
    end
  end

end
