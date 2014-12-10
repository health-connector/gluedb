require 'rails_helper'

describe Policies::CreatePolicy do
  let(:listener) { double(:fail => nil, :policy_already_exists => nil, :plan_not_found => nil) }
  let(:request) { { :enrollment_group_id => enrollment_group_id, :hios_id => hios_id, :plan_year => plan_year, :enrollees => enrollees } }
  let(:hios_id) { "DLJKFKLSDJEF" }
  let(:enrollment_group_id) { "LSJKDKLFJEF" }
  let(:existing_policy) { nil }
  let(:plan_year) { "2015" }
  let(:carrier) { double }
  let(:plan) { double(:carrier => carrier) }
  let(:subscriber) { double(:person => person, :coverage_start => coverage_start) }
  let(:enrollees) { [subscriber_hash] }
  let(:subscriber_hash) { { }}
  let(:policy_factory) { double(:new => new_policy) }
  let(:new_policy) { double(:valid? => valid_policy, :errors => policy_errors) }
  let(:valid_policy) { true }
  let(:policy_errors) { { "an error" => "a reason" } }
  let(:policy_id) { double }
  let(:policy) { double(:id => policy_id, :subscriber => subscriber, :coverage_type => coverage_type) }
  let(:person) { double(:policies => existing_policies) }
  let(:coverage_start) { nil }
  let(:coverage_type) { "health" }

  let(:existing_policies) { [] }

  subject { Policies::CreatePolicy.new(policy_factory) }

  before :each do
    allow(policy_factory).to receive(:find_for_group_and_hios).with(
      enrollment_group_id,
      hios_id
    ).and_return(existing_policy)
    allow(Plan).to receive(:find_by_hios_id_and_year).with(
      hios_id,
      plan_year
    ).and_return(plan)
  end

  it "should validate" do
    expect(subject.validate(request, listener)).to be_truthy
  end

  describe "with an invalid policy" do
    let(:valid_policy) { false }

    it "should notify the listener of failure" do
      expect(listener).to receive(:invalid_policy).with(policy_errors)
      expect(subject.validate(request, listener)).to be_falsey
    end
  end

  describe "with an already existing policy" do
    let(:existing_policy) { double }

    it "should notify the listener of failure" do
      expect(listener).to receive(:policy_already_exists).with({
        :enrollment_group_id => enrollment_group_id,
        :hios_id => hios_id
      })
      expect(subject.validate(request, listener)).to be_falsey
    end
  end

  describe "with a plan that doesn't exist" do
    let(:plan) { nil }

    it "should notify the listener of failure" do
      expect(listener).to receive(:plan_not_found).with({
        :hios_id => hios_id,
        :plan_year => plan_year
      })
      expect(subject.validate(request, listener)).to be_falsey
    end
  end

  describe "with a broker that doesn't exist" do
    let(:npn) { "andskflnsdf" }
    let(:broker_request) { request.merge({:broker_npn => npn}) }

    before(:each) do
      allow(Broker).to receive(:find_by_npn).with(npn).and_return(nil)
    end

    it "should notify the listener of failure" do
      expect(listener).to receive(:broker_not_found).with({:npn => npn})
      expect(subject.validate(broker_request, listener)).to be_falsey
    end
  end

  describe "with no enrollees" do
    let(:enrollees) { [] }

    it "should notify the listener of failure" do
      expect(listener).to receive(:no_enrollees)
      expect(subject.validate(request, listener)).to be_falsey
    end
  end

  describe "persisting a policy" do
    let(:create_params) {
      request.merge({
        :plan => plan,
        :carrier => carrier,
        :broker => nil,
        :employer => nil
      })
    }

    it "should create the policy" do
      expect(policy_factory).to receive(:create!).with(create_params).and_return(policy)
      expect(listener).to receive(:policy_created).with(policy_id)
      subject.commit(request, listener)
    end

    describe "with an existing policy that qualifies for cancellation" do
      let(:to_be_cancelled_policy) { double(:policy_start => coverage_start, :coverage_type => coverage_type, :id => "1234", :active_as_of? => true) } 
      let(:existing_policies) { [to_be_cancelled_policy] }

      it "should tell the listener to cancel that policy" do
        expect(policy_factory).to receive(:create!).and_return(policy)
        expect(listener).to receive(:policy_created).with(policy_id)
        expect(to_be_cancelled_policy).to receive(:cancel_via_hbx!)
        expect(listener).to receive(:policy_canceled).with("1234")
        subject.commit(request, listener)
      end
    end

    describe "with a broker" do
      let(:npn) { "andskflnsdf" }
      let(:broker_create_params) { create_params.merge(:broker => broker, :broker_npn => npn) }
      let(:broker_request) { request.merge(:broker_npn => npn) }
      let(:broker) { double }

      before(:each) do
        allow(Broker).to receive(:find_by_npn).with(npn).and_return(broker)
      end

      it "should create the policy" do
        expect(policy_factory).to receive(:create!).with(broker_create_params).and_return(policy)
        expect(listener).to receive(:policy_created).with(policy_id)
        subject.commit(broker_request, listener)
      end
    end
  end
end
