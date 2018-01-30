require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_enrollee_end_date")

describe ChangeEnrolleeEndDate, dbclean: :after_each do 
  let(:given_task_name) { "change_enrollee_end_date" }
  let(:policy) { FactoryGirl.create(:policy) }
  let (:enrollees) { policy.enrollees }
  let(:end_date) { (policy.policy_start + 2.months).end_of_month}
  subject { ChangeEnrolleeEndDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the end dates for a policy" do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("enrollee_id").and_return(policy.enrollees.first.id)
      allow(ENV).to receive(:[]).with("new_end_date").and_return('01/31/2017')
    end

    it "should have an end date" do
      subject.deactivate_enrollees
      policy.reload
      expect(policy.enrollees.where(id: enrollee_id).first.coverage_end).to eq ['end_date'].to_date
    end
  end
end