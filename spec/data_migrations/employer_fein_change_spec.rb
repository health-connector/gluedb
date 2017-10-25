require "rails_helper"
require File.join(Rails.root,"app","data_migrations","employer_fein_change")

describe EmployerFeinChange, dbclean: :after_each do
  let(:given_task_name) { "employer_fein_change" }
  let(:employer_1) { FactoryGirl.create(:employer_with_plan_year) }
  let(:employer_2) { FactoryGirl.create(:employer_with_plan_year) }
  subject { EmployerFeinChange.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'the fein change task' do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("employer_id").and_return(employer_1._id)
      allow(ENV).to receive(:[]).with("new_fein").and_return((employer_1.fein.to_i + 5).to_s)
    end

    it 'should change the FEIN if there are no other identical FEINs' do 
      subject.migrate
      employer_1.reload
      expect(employer_1.fein).to eql ENV['new_fein']
    end

    it 'should not change the FEIN if there is an existing FEIN' do 
      allow(ENV).to receive(:[]).with("new_fein").and_return(employer_2.fein)
      old_fein = employer_1.fein
      subject.migrate
      expect(employer_1.fein).to eql old_fein
      expect(employer_1.fein).not_to eql employer_2.fein
    end
  end
end