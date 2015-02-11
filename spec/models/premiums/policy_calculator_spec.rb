require 'rails_helper'

describe Premiums::PolicyCalculator do
  describe "given an individual policy" do
    let(:policy) { Policy.new(:applied_aptc => original_aptc) }
    let(:subscriber) { instance_double("Enrollee", :coverage_start => coverage_start, :member => member) }
    let(:member) { instance_double("Member", :dob => dob) }
    let(:plan) { instance_double("Plan", :ehb => 0.5) }
    let(:ehb_max_aptc) { 106.99 }
    let(:dob) { Date.new(1985, 12, 17) }
    let(:coverage_start) { Date.new(2015, 1, 1) }
    let(:premium) { 213.98 }
    let(:rate_result) { double(:amount => premium) }
    subject { Premiums::PolicyCalculator.new }

    before :each do
      allow(policy).to receive(:enrollees).and_return([subscriber])
      allow(policy).to receive(:plan).and_return(plan)
      allow(plan).to receive(:rate).with(coverage_start,coverage_start,dob).and_return(rate_result)
      allow(subscriber).to receive(:pre_amt=).with(premium)
      allow(subscriber).to receive(:pre_amt).and_return(premium)
      subject.apply_calculations(policy)
    end

    describe "with APTC equal to the premium total times the EHB" do
      let(:original_aptc) { 106.99 }
      it "should keep the aptc value" do
        expect(policy.applied_aptc).to eq original_aptc
      end
    end
    describe "with APTC less than the premium total times the EHB" do
      let(:original_aptc) { 12.00 }
      it "should keep the aptc value" do
        expect(policy.applied_aptc).to eq original_aptc
      end
    end
    describe "with APTC greater than the premium total times the EHB" do
      let(:original_aptc) { 529.13 }
      it "should set the aptc to the premium total" do
        expect(policy.applied_aptc).to eq ehb_max_aptc
      end
    end
  end
end
