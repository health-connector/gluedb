require "rails_helper"

describe EnrollmentAction::RenewalComparisonHelper do
  subject { Class.new { extend EnrollmentAction::RenewalComparisonHelper } }

  describe "#any_renewal_candidates?" do
    ## receives an EnrollmentEvent

  end

  describe "#same_carrier_renewal_candidates" do
    let(:enrollment_event) { instance_double(ExternalEvents::EnrollmentEventNotification)}
    ## receives an EnrollmentEvent
  end

  describe "#renewal_dependents_changed?" do
    ## receives EnrollmentEvent and a renewal candidate
  end

  describe "#renewal_dependents_added?" do
    ## receives EnrollmentEvent and a renewal candidate

  end

  describe "#renewal_dependents_dropped?" do
    ## receives EnrollmentEvent and a renewal candidate

  end

  describe "ivl_renewal_candidate?" do
    ## receives a policy, plan, subscriber_id, subscriber_start date, and a boolean if same carrier
  end
  describe "shop_renewal_candidate?" do
    ## receives a policy, plan, subscriber_id, subscriber_start date, and a boolean if same carrier
    let(:subscriber) { double(:m_id => 1)}
    let(:employer) { double(id: 1) }
    let(:policy_employer_id) { 1 }
    let(:old_plan) { instance_double(Plan, :year => 2016, :carrier_id => 1, :coverage_type => :some_type)}
    let(:new_plan) { instance_double(Plan, :year => 2017, :carrier_id => 1, :coverage_type => :some_type) }
    let(:same_carrier) { true }
    let(:canceled?) { false }
    let(:subscriber_id) { 1 }
    let(:subscriber_start) { DateTime.new(2017,1,1) }
    let(:old_coverage_period) { double(:end => subscriber_start - 1.day) }

    let(:policy) { instance_double(Policy,
                    :canceled? => canceled?,
                    :subscriber => subscriber,
                    :employer_id => policy_employer_id,
                    :plan => old_plan,
                    :coverage_period => old_coverage_period)
                  }

    it "returns true for the matching cases" do
      expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_truthy
    end

    context "the policy does not include an employer_id" do
      let(:policy_employer_id) { nil }
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "the policy is cancelled" do
      let(:canceled?) { true }
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "the policy subscriber is blank" do
      let(:subscriber) { nil }
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "the policy's subscriber member id does not match the new subscriber_id" do
      let(:subscriber) { double(:m_id => 4) }
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "the policy coverage type changed" do
      let(:new_plan) { instance_double(Plan, :year => 2017, :carrier_id => 1, :coverage_type => :new_type)}
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "the employer does not match" do
      let(:policy_employer_id) { 2 }
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "the plan years dont align" do
      let(:new_plan) { instance_double(Plan, :year => 2018, :carrier_id => 1, :coverage_type => :some_type)}
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "carrier unchanged but same_carrier is false" do
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, false)).to be_falsey
      end
    end

    context "carrier changed but same_carrier is true" do
      let(:new_plan) { instance_double(Plan, :year => 2017, :carrier_id => 2, :coverage_type => :some_type)}
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end

    context "returns false if there is a gap between coverage end and subscriber_start" do
      let(:old_coverage_period) { double(:end => subscriber_start - 2.day) }
      it "returns false" do
        expect(subject.shop_renewal_candidate?(policy, new_plan, employer, subscriber_id, subscriber_start, same_carrier)).to be_falsey
      end
    end
  end

  describe "shop_renewal_candidates" do
    ## receives a policy_cv and boolean if same carrier
  end

  describe "extract_ivl_policy_details" do
    ## receives policy_cv
  end
end
