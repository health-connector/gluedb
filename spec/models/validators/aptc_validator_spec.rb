require 'rails_helper'

describe Validators::AptcValidator do
  let(:plan) { instance_double("Plan", :ehb => ehb) }
  let(:change_request) { double(:credit => aptc_amount, :premium_amount_total => premium_total) }
  let(:premium_total) { 213.98 }
  let(:ehb) { 0.5 }
  let(:listener) { double() }
  let(:aptc_amount) { 213.98 }
  let(:subject) { Validators::AptcValidator.new(change_request, plan, listener) }

  describe "given a shop policy" do
    before(:each) do
      allow(change_request).to receive(:respond_to?).with(:employer).and_return(true)
    end
    it "is always valid" do
      expect(subject.validate).to be_truthy
    end
  end

  describe "given an individual policy" do
    before(:each) do
      allow(change_request).to receive(:respond_to?).with(:employer).and_return(false)
    end
    describe "with APTC equal to the premium total times the EHB" do
      let(:aptc_amount) { 106.99 }
      it "should be valid" do
        expect(subject.validate).to be_truthy
      end
    end
    describe "with APTC less than the premium total times the EHB" do
      let(:aptc_amount) { 10.83 }
      it "should be valid" do
        expect(subject.validate).to be_truthy
      end
    end
    describe "with APTC greater than the premium total times the EHB" do
      let(:aptc_amount) { 107.00 }
      it "should not be valid" do
        expect(listener).to receive(:aptc_too_large).with({:expected => 106.99, :provided => aptc_amount})
        expect(subject.validate).to be_falsey
      end
    end
  end
end
