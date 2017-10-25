require "rails_helper"
require File.join(Rails.root,"app","data_migrations","terminate_plan_year")

describe TerminatePlanYear, dbclean: :after_each do
  let(:given_task_name) { "terminate_plan_year" }
  let(:employer) { FactoryGirl.create(:employer_with_plan_year)}
  let(:plan_year) { employer.plan_years.first}
  let(:start_date) { plan_year.start_date.to_s }
  let(:new_end_date) { (plan_year.end_date - 1.month).to_s }
  subject { TerminatePlanYear.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "terminating_the_plan_year" do 

    before(:each) do 
      allow(ENV).to receive(:[]).with("fein").and_return(employer.fein)
      allow(ENV).to receive(:[]).with("start_date").and_return(start_date)
      allow(ENV).to receive(:[]).with("new_end_date").and_return(new_end_date)
    end

    it 'should change the end date' do
      subject.migrate
      plan_year.reload
      expect(plan_year.end_date.to_s).to eq ENV["new_end_date"]
    end

  end
end