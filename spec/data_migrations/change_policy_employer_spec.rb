require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_policy_employer")

describe ChangePolicyEmployer, dbclean: :after_each do 
  let(:given_task_name) { "change_policy_employer" }
  let(:policy) { FactoryGirl.create(:policy) }
  let(:employer) { FactoryGirl.create(:employer) }
  subject { ChangePolicyEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the employer" do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_ids").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("employer_id").and_return(employer.id)
    end

    it 'should change the employer' do 
      subject.migrate
      policy.reload
      expect(policy.employer_id).to eq employer.id
    end
  end
end