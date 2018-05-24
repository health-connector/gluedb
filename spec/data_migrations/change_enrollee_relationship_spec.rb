require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_enrollee_relationship")

describe ChangeEnrolleeRelationship, dbclean: :after_each do 
  let(:given_task_name) { "change_enrollee_relationship" }
  let(:policy) { FactoryGirl.create(:policy) }
  let(:enrollee) { policy.enrollees.first }
  let(:new_relationship) { "life partner" }
  subject { ChangeEnrolleeRelationship.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update the member ID" do 

    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("hbx_id").and_return(enrollee.m_id)
      allow(ENV).to receive(:[]).with("new_relationship").and_return(new_relationship)
    end

    it 'should change the member id' do 
      subject.migrate
      enrollee.reload
      expect(enrollee.rel_code).to eq new_relationship
    end
    
  end
end