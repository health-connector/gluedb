require "rails_helper"

describe PolicyInteractions::PlanChange do

  let(:new_policy) { instance_double("Policy", :coverage_period => (Date.new(2015,1,1)..Date.new(2015, 12,31)), :carrier_id => 5) }
  let(:existing_policies) { [] }

  describe "with no exising policies" do
    it "should not qualify for plan change" do
      expect(subject.qualifies?(existing_policies, new_policy)).to be_falsey
    end
  end

  describe "with a policy with an overlapping coverage period" do
    let(:existing_policies) { [overlapping_policy] }

    describe "with the same carrier" do
      let(:overlapping_policy) { instance_double("Policy", :coverage_period => (Date.new(2015,2,1)..Date.new(2015, 10,31)), :carrier_id => 5) }
      it "should qualify for plan change" do
        expect(subject.qualifies?(existing_policies, new_policy)).to be_truthy
      end
    end

    describe "with a different carrier" do
      let(:overlapping_policy) { instance_double("Policy", :coverage_period => (Date.new(2015,2,1)..Date.new(2015, 10,31)), :carrier_id => 7) }
      it "should not qualify for plan change" do
        expect(subject.qualifies?(existing_policies, new_policy)).to be_falsey
      end

    end
  end
end
