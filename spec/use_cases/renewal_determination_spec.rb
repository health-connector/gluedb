require "rails_helper"

describe RenewalDetermination do
  let(:person_finder) { double }
  let(:plan_finder) { double }
  let(:listener) { instance_double("Listeners::NewEnrollmentListener") }

  let(:request) {
    {
      :policies => policies,
      :individuals => individuals
    }
  }

  let(:policies) { [policy] }
  let(:individuals) { [subscriber_person] }
  let(:policy) { {
    :enrollees => enrollees,
    :plan_year => plan_year,
    :hios_id => hios_id
  } }

  let(:coverage_type) { "health" }
  let(:plan_year) { double }
  let(:hios_id) { double }
  let(:subscriber_person) { { :hbx_member_id => "12345" } }
  let(:enrollees) { [subscriber] }
  let(:subscriber) { 
    {
      :rel_code => "self",
      :m_id => "12345",
      :coverage_start => Date.new(2015, 1, 1)
    }
  }

  subject { RenewalDetermination.new(person_finder, plan_finder) }

  describe "with no existing subscriber" do
    let(:enrollees) { [] }
    it "should notify the listener" do
      expect(listener).to receive(:no_subscriber_for_policies)
      expect(subject.validate(request, listener)).to be_falsey
    end
  end

  describe "with a subscriber who has no member" do
    before :each do
      allow(person_finder).to receive(:find_person_and_member).with(subscriber_person).and_return(["abcd", nil])
    end 

    it "should validate" do
      expect(subject.validate(request, listener)).to be_truthy
    end
  end
  

  describe "with a subscriber who has a member" do
    let(:person) { double }
    let(:member) { double }
    let(:person) { double(:policies => found_policies) }
    let(:found_policies) { [] }

    before :each do
      allow(person_finder).to receive(:find_person_and_member).with(subscriber_person).and_return([person, member])
    end 

    describe "with no found policies" do
      let(:found_policies) { [] }

      it "should validate" do
        expect(subject.validate(request, listener)).to be_truthy
      end
    end

    describe "with a previous policy in the same market, with more enrollees" do
      let(:previous_policy) { 
        instance_double("Policy",
                        :plan => existing_plan, :subscriber => existing_sub, :eg_id => nil, :id => nil, :canceled? => false, :coverage_type => coverage_type, :coverage_period => (Date.new(2014,12,1)..Date.new(2014,12,31)), :terminated? => false, :carrier_id => carrier_id, :enrollees => found_enrollees, :policy_start => Date.new(2014,12,1)) }
      let(:found_policies) { [previous_policy] }
      let(:policy_plan) { double(:coverage_type => coverage_type, :carrier_id => carrier_id) }
      let(:existing_plan) { double(:coverage_type => coverage_type, :carrier_id => carrier_id) }
      let(:existing_sub) { double(:coverage_end => nil, :coverage_start => Date.new(2014,12,1), :m_id => 123) }
      let(:existing_dep) { double(:coverage_end => nil, :coverage_start => Date.new(2014,12,1), :m_id => 654) }
      let(:carrier_id) { double }
      let(:found_enrollees) { [existing_sub, existing_dep] }

      before :each do
        allow(plan_finder).to receive(:find_by_hios_id_and_year).with(hios_id, plan_year).and_return(policy_plan)  
        allow(previous_policy).to receive(:is_shop?).and_return(false)
        allow(previous_policy).to receive(:active_as_of?).with(Date.new(2014,12,31)).and_return(true)
        allow(previous_policy).to receive(:active_on_date_for?).with(Date.new(2014,12,31), 123).and_return(true)
        allow(previous_policy).to receive(:active_on_date_for?).with(Date.new(2014,12,31), 654).and_return(true)
      end

      it "should fail validation and notify the listener" do
        expect(listener).to receive(:enrollees_changed_for_renewal).with({old_policy:2, new_policy:1})
        expect(subject.validate(request, listener)).to be_falsey
      end

    end

    describe "with policies in the interval, but with a different carrier" do
      let(:bad_policy) { instance_double("Policy", :plan => existing_plan, :subscriber => existing_sub, :eg_id => nil, :id => nil, :canceled? => false, :coverage_type => coverage_type, :coverage_period => (Date.new(2014,12,1)..Date.new(2014,12,31)), :terminated? => false, :carrier_id => carrier_id, :is_shop? => false) }
      let(:found_policies) { [bad_policy] }
      let(:policy_plan) { double(:coverage_type => coverage_type, :carrier_id => carrier_id_new) }
      let(:existing_plan) { double(:coverage_type => coverage_type, :carrier_id => carrier_id) }
      let(:existing_sub) { double(:coverage_end => nil) }
      let(:carrier_id) { double }
      let(:carrier_id_new) { double }

      before :each do
        allow(plan_finder).to receive(:find_by_hios_id_and_year).with(hios_id, plan_year).and_return(policy_plan)        
        allow(bad_policy).to receive(:policy_start).and_return(Date.new(2014,12,1))
      end

      it "should notify the listener of the error" do
        expect(listener).to receive(:carrier_switch_renewal)
        expect(subject.validate(request, listener)).to be_falsey
      end
    end
  end

end
