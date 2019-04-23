require "rails_helper"
require File.join(Rails.root,"app","data_migrations","remove_issuer_ids_from_plan_year")

describe RemoveIssuerIdsFromPlanYear, dbclean: :after_each do
  let(:given_task_name) { "change_plan_year_dates" }
  let(:employer_1) { FactoryGirl.create(:employer_with_plan_year) }
  let(:start_date) {"01-01-2014"}
  let(:carrier1) {FactoryGirl.create(:carrier)}
  let(:carrier2) {FactoryGirl.create(:carrier)}
  let(:issuer_id) {carrier1.id.to_s}
  let(:issuer_ids) {[carrier1.id.to_s, carrier2.id.to_s]}
  let!(:update_plan_year) {
    plan_year = employer_1.plan_years.first
    plan_year.issuer_ids = issuer_ids
    plan_year.save
  }
  subject { RemoveIssuerIdsFromPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'Change Plan_Year start_date and end_date' do
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(employer_1.hbx_id)
      allow(ENV).to receive(:[]).with("start_date").and_return(employer_1.plan_years.first.start_date)
      allow(ENV).to receive(:[]).with("issuer_id").and_return(issuer_id)
    end

    it 'should remove issuer_id from plan year' do
      expect(employer_1.plan_years.first.start_date.to_s).to eql start_date
      expect(employer_1.plan_years.first.issuer_ids).to eq [carrier1.id, carrier2.id]
      subject.migrate
      employer_1.reload
      expect(employer_1.plan_years.first.issuer_ids).to eq [carrier2.id]
    end
  end
end
