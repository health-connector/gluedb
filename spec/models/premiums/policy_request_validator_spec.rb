require "rails_helper"

describe Premiums::PolicyRequestValidator do

  let(:hios_id) { "12345" }
  let(:plan_year) { "2005" }

  let(:plan) { double }
  let(:listener) { double }
  let(:request) { {
    :hios_id => hios_id,
    :plan_year => plan_year,
    :enrollees => enrollees,
    :pre_amt_tot => pre_amt_tot,
    :tot_res_amt => tot_res_amt
  }.merge(additional_keys) }

  let(:additional_keys) { {
  
  } }

  let(:subscriber_dob) { Date.new(1983, 2, 7) }
  let(:coverage_start) { Date.new(2015, 2, 7) }
  let(:enrollees) { [subscriber] }
  let(:subscriber) { {
    :coverage_start => coverage_start.strftime("%Y%m%d"),
    :member => { :dob =>  subscriber_dob },
    :rel_code => 'self',
    :pre_amt => subscriber_premium
  } }
  let(:pre_amt_tot) { 282.03 }
  let(:tot_res_amt) { 282.03 }
  let(:subscriber_premium) { 282.03 }

  before :each do
    allow(Plan).to receive(:find_by_hios_id_and_year).with(hios_id, plan_year).and_return(plan)
  end

  describe "given an individual policy" do
    before :each do
      allow(plan).to receive(:rate).with(coverage_start, coverage_start, subscriber_dob).and_return(OpenStruct.new(:amount => 282.03))
    end

    describe "with correct premiums for a subscriber" do
      describe "with no aptc" do
        it "should validate" do
          expect(subject.validate(request, listener)).to be_truthy
        end
      end

      describe "with aptc" do
        let(:additional_keys) { { :applied_aptc => 5.27 } }
        let(:tot_res_amt) { 276.76 }

        it "should validate" do
          expect(subject.validate(request, listener)).to be_truthy
        end
      end
    end
  end

  describe "for a shop employee" do
    let(:employer_fein) { "123456" }
    let(:employer) { double(:id => "1234234") }
    let(:additional_keys) { { :employer_fein => employer_fein, :tot_emp_res_amt => employer_contribution } }
    let(:plan_year) { double(:start_date => plan_year_start, :contribution_strategy => contribution_strategy) }
    let(:plan_year_start) { double }
    let(:contribution_strategy) { double }
    let(:employer_contribution) { 12.31 }
    let(:tot_res_amt) { 269.72 }

    before(:each) do
      allow(Employer).to receive(:find_for_fein).with(employer_fein).and_return(employer)
      allow(employer).to receive(:plan_year_of).with(coverage_start).and_return(plan_year)
      allow(plan).to receive(:rate).with(plan_year_start, coverage_start, subscriber_dob).and_return(OpenStruct.new(:amount => 282.03))
      allow(contribution_strategy).to receive(:contribution_for).and_return(employer_contribution)
    end

    it "should validate" do
      expect(subject.validate(request, listener)).to be_truthy
    end

  end

end
