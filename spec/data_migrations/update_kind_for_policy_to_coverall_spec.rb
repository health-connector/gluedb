require "rails_helper"
require File.join(Rails.root,"app","data_migrations","update_kind_for_policy_to_coverall")

describe UpdateKindForPolicyToCoverall, dbclean: :after_each do
  let(:given_task_name) { "update_kind_for_policy_to_coverall" }
  # policy factory generates a policy with the kind atrribute set to "individual" by default
  # this will verify that the rake task is actually making a change and that the test instance
  # does not have the correct value already
  let(:policy) { FactoryGirl.create(:policy) }
  subject { UpdateKindForPolicyToCoverall.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating the kind attribute to be coverall" do
    before(:each) do
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
    end

    it "should have a kind attribute equal to coverall" do
      subject.migrate
      policy.reload
      expect(policy.kind).to eq "coverall"
    end
  end
end