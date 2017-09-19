require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_policy_start_date")

describe ChangePolicyStartDate, dbclean: :after_each do 
  let(:given_task_name) { "change_policy_start_date" }
  let(:policy) { FactoryGirl.create(:policy) }
  let (:enrollees) { policy.enrollees }
  let(:new_start_date) { policy.policy_start + 1.month }
  subject { ChangePolicyStartDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the start dates for a policy" do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("new_start_date").and_return(new_start_date)
    end

    it "should change the effective date of all the enrollees" do
      subject.move_effective_date(policy,ENV['new_start_date'])
      policy.reload
      expect(policy.policy_start).to eq ENV['new_start_date'].to_date
    end
  end
end