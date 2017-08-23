require "rails_helper"
require File.join(Rails.root,"app","data_migrations","employer_fein_removal")

describe EmployerFeinRemoval, dbclean: :after_each do
  let(:given_task_name) { "employer_fein_removal" }
  let(:employer_1) { FactoryGirl.create(:employer_with_plan_year) }
  subject { EmployerFeinRemoval.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'the fein change task' do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("employer_id").and_return(employer_1._id)
    end

    it 'should remove the FEIN' do 
      subject.migrate
      employer_1.reload
      expect(employer_1.fein).to eql nil
    end
  end
end