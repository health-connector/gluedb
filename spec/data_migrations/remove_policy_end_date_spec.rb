require "rails_helper"
require File.join(Rails.root,"app","data_migrations","remove_policy_end_date")

describe RemovePolicyEndDate, dbclean: :after_each do 
  let(:given_task_name) { "remove_policy_end_date" }
  let(:policy) { FactoryGirl.create(:terminated_policy) }
  let (:enrollees) { policy.enrollees }
  subject { RemovePolicyEndDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "removing the end dates" do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("benefit_status").and_return('active')
    end

    it "should not have any end dates" do
      subject.remove_end_dates
      policy.reload
      expect(policy.enrollees.map(&:coverage_end).uniq[0]).to be_nil
      expect(policy.enrollees.first.ben_stat).to eq 'active'
    end
  end

  describe "altering the aasm state" do 
    before(:each) do
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id) 
      allow(ENV).to receive(:[]).with("aasm_state").and_return(policy.aasm_state)
    end

    it "should alter the aasm state" do 
      aasm_state = policy.aasm_state
      expect(policy.aasm_state).to eq aasm_state
      subject.change_aasm_state
      expect(policy.aasm_state).to eq ENV['aasm_state']
    end
  end
end