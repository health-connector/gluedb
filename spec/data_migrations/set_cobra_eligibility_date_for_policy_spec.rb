require "rails_helper"
require File.join(Rails.root,"app","data_migrations","set_cobra_eligibility_date_for_policy")

describe SetCobraEligibilityDateForPolicy, dbclean: :after_each do
  let(:given_task_name) {"set_cobra_eligibility_date_for_policy"}
  let(:employer) {FactoryGirl.create(:employer)}
  let!(:policy) {FactoryGirl.create(:policy,employer:employer)}
  let(:enrollees) {policy.enrollees}
  let!(:subscriber) {policy.subscriber}
  subject { SetCobraEligibilityDateForPolicy.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "should set cobra_eligibility_date for policy" do

    before(:each) do
      policy.subscriber.update_attributes(ben_stat:'cobra')
    end

    it "should change the effective date of all the enrollees" do
      expect(policy.cobra_eligibility_date).to eq nil  # before migration
      subject.migrate
      policy.reload
      expect(policy.cobra_eligibility_date).to eq subscriber.coverage_start  # after migration
    end
  end
end