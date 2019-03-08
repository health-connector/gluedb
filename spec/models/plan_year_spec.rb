require 'rails_helper'

describe PlanYear do
  describe "#PlanYear" do
    let(:plan_year) {FactoryGirl.create(:plan_year)}

    it { should belong_to :employer }
    it { should belong_to :broker }

    it 'should have the expected fields' do
      fields = %w(
        _id
        created_at
        updated_at
        start_date
        end_date
        open_enrollment_start
        open_enrollment_end
        fte_count
        pte_count
        issuer_ids
        employer_id
        broker_id
      )

      fields.each do  |field_name|
         expect(PlanYear.fields.keys).to include(field_name)
      end
    end
  end

  describe 'associated with issuers' do
    let(:issuer1) {Carrier.new}
    let(:issuer2) {Carrier.new}

    before(:each) do
     subject.issuers = [issuer1, issuer2]
    end

    it 'is associated with issuer 1' do
      expect(subject.issuer_ids).to include(issuer1.id)
    end

    it 'is associated with issuer 2' do
      expect(subject.issuer_ids).to include(issuer2.id)
    end
  end

  describe "scope#by_start_date", dbclean: :after_each do
    let(:employer) { FactoryGirl.create(:employer_with_plan_year)}
    let(:plan_year) { employer.plan_years.first}

    context "should find matched start date plan year" do

      it "returns plan year" do
        expect(employer.plan_years.by_start_date(plan_year.start_date)).to include plan_year
      end
    end
  end

  describe ".for_employer_starting_on", :dbclean => :after_each do
    let(:start_date) { Date.today }
    let(:other_start_date) { Date.today - 1.year }
    let(:expected_query_results) { double }
    let(:employer_id) { Moped::BSON::ObjectId.new }
    let(:employer) { instance_double(Employer, :id => employer_id) }
    let(:other_employer_id) { Moped::BSON::ObjectId.new }
    let(:matching_plan_year) { PlanYear.create!(:employer_id => employer_id, :start_date => start_date) }
    let(:plan_year_with_different_date) { PlanYear.create!(:employer_id => employer_id, :start_date => other_start_date) }
    let(:plan_year_with_different_employer) { PlanYear.create!(:employer_id => other_employer_id, :start_date => start_date) }

    it "returns plan years for a given employer and start date" do
      plan_years = [matching_plan_year, plan_year_with_different_date, plan_year_with_different_employer]
      query_results = PlanYear.for_employer_starting_on(employer, start_date)
      expect(query_results).to include(matching_plan_year)
      expect(query_results).not_to include(plan_year_with_different_date)
      expect(query_results).not_to include(plan_year_with_different_employer)
    end
  end

  describe "#add_issuer", dbclean: :after_each do
    let(:fake_employer_id) { Moped::BSON::ObjectId.new }
    let(:start_date) { Date.today }
    let(:issuer_id) { Moped::BSON::ObjectId.new }
    let(:issuer) { instance_double(Carrier, :id => issuer_id) }

    subject { PlanYear.new(:employer_id => fake_employer_id, :start_date => start_date) }

    it "adds the issuer if they are not already on the plan year" do
      expect(subject.issuer_ids).not_to include issuer.id
      subject.add_issuer(issuer)
      expect(subject.issuer_ids).to include issuer.id
    end
  end
end
