require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_plan_year_dates")

describe ChangePlanYearDates, dbclean: :after_each do
  let(:given_task_name) { "change_plan_year_dates" }
  let(:employer_1) { FactoryGirl.create(:employer_with_plan_year) }
  let(:old_start_date) {"01-01-2014"}
  let(:old_end_date) {"12-31-2014"}
  let(:start_date){"10-01-2018"}
  let(:end_date) {"10-31-2018"}
  subject { ChangePlanYearDates.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'Change Plan_Year start_date and end_date' do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("hbx_id").and_return(employer_1.hbx_id)
      allow(ENV).to receive(:[]).with("old_start_date").and_return(employer_1.plan_years.first.start_date)
      allow(ENV).to receive(:[]).with("new_start_date").and_return("10/01/2018")
      allow(ENV).to receive(:[]).with("new_end_date").and_return("10/31/2018")
    end

    it 'should update the new plan year start date and end date' do 
      expect(employer_1.plan_years.first.start_date.to_s).to eql old_start_date
      subject.migrate
      employer_1.reload
      expect(employer_1.plan_years.first.start_date.to_s).to eql start_date
      expect(employer_1.plan_years.first.end_date.to_s).to eql end_date
    end


    it 'should not update the new plan year start date and end date' do
      allow(ENV).to receive(:[]).with("new_start_date").and_return("")
      allow(ENV).to receive(:[]).with("new_end_date").and_return("")
      expect(employer_1.plan_years.first.start_date.to_s).to eql old_start_date
      subject.migrate
      employer_1.reload
      expect(employer_1.plan_years.first.start_date.to_s).to eql old_start_date
      expect(employer_1.plan_years.first.end_date.to_s).to eql old_end_date
    end
  end
end
