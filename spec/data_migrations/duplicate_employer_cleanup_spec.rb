require "rails_helper"
require File.join(Rails.root,"app","data_migrations","duplicate_employer_cleanup")

describe DuplicateEmployerCleanup, dbclean: :after_each do
  let(:given_task_name) { "duplicate_employer_cleanup" }
  let(:good_employer) { FactoryGirl.create(:employer_with_plan_year) }
  let(:bad_employer) { FactoryGirl.create(:employer_with_plan_year) }
  let(:bad_employer_plan_year) { bad_employer.plan_years.first }
  let(:policy) { FactoryGirl.create(:shop_policy, employer: bad_employer) }
  let(:bad_employer_premium_payment) { policy.premium_payments.first }
  subject { DuplicateEmployerCleanup.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "it should change employer data" do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("bad_employer_id").and_return(bad_employer._id)
      allow(ENV).to receive(:[]).with("good_employer_id").and_return(good_employer._id)
    end

    it 'should move the plan years on the bad employer to the good employer' do
      bad_employer_plan_year.start_date += 1.year
      bad_employer_plan_year.end_date += 1.year
      bad_employer_plan_year.save
      subject.move_plan_years
      bad_employer_plan_year.reload
      expect(bad_employer_plan_year.employer).to eql good_employer
    end

    it 'should move the premium payments on the bad employer to the good employer' do
      bad_employer_premium_payment.reload
      subject.move_premium_payments
      bad_employer_premium_payment.reload
      expect(bad_employer_premium_payment.employer).to eql good_employer
    end

    it 'should update the bad employers name' do
      bad_name = bad_employer.name 
      subject.update_bad_employer_name
      bad_employer.reload
      expect(bad_employer.name).to eql "OLD DO NOT USE " + bad_name
    end

    it 'should move the policies' do
      policy.reload 
      subject.move_policies
      policy.reload
      expect(policy.employer).to eql good_employer
    end
  end

end