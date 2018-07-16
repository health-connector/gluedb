require "rails_helper"
require File.join(Rails.root,"app","data_migrations","add_plan_catalog_override")

describe AddPlanCatalogOverride, dbclean: :after_each do
  let(:given_task_name) { "add_plan_catalog_override" }
  let(:employer) { FactoryGirl.create(:employer_with_plan_year)}
  let(:plan_year) { employer.plan_years.first}
  let(:start_date) { plan_year.start_date }
  let(:data) { {"FEIN" => employer.fein, "Start Date" => start_date.strftime("%m-%e-%Y"), "override_integer" => 2017 } }
  subject { AddPlanCatalogOverride.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "adding_the_override_thing" do 

    it 'should find the plan year' do
      test_py = subject.find_plan_year(data["FEIN"],start_date)
      expect(test_py).to eq plan_year
    end

    it 'should add the plan year override field' do 
      test_py = subject.find_plan_year(data["FEIN"],start_date)
      subject.add_override(test_py,data["override_integer"])
      plan_year.reload
      expect(plan_year.plan_catalog_override).to eq data["override_integer"]
    end

  end
end