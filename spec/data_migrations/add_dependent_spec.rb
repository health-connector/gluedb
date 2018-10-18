require "rails_helper"
require File.join(Rails.root,"app","data_migrations","add_dependent")

describe AddDependent, dbclean: :after_each do
  let(:given_task_name) { "add_dependent" }
  let!(:person) { FactoryGirl.create(:person) }
  let!(:person_2) { FactoryGirl.create(:person) }
  let!(:policy) { FactoryGirl.create(:policy) }

  subject { AddDependent.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'adding a dependent' do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("rel_code").and_return("child")
      allow(ENV).to receive(:[]).with("coverage_start").and_return("10/03/2018")
      allow(ENV).to receive(:[]).with("coverage_end").and_return("10/03/2018")
    end
    
    it 'adds the dependent if it does not exist' do 
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.authority_member_id)
      person.save!
      
      subject.migrate
      person.reload
      policy.reload

      expect(policy.enrollees.where(m_id: person.authority_member_id).first.rel_code).to eq("child")
      expect(policy.enrollees.map(&:m_id)).to include(person.authority_member_id)
    end

    it 'adds another dependent' do  
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person_2.authority_member_id)
      allow(ENV).to receive(:[]).with("rel_code").and_return("self")
      person_2.save!

      subject.migrate
      person_2.reload
      policy.reload

      expect(policy.enrollees.map(&:m_id)).to include(person_2.authority_member_id)
      expect(policy.enrollees.where(m_id: person_2.authority_member_id).first.rel_code).to eq("self")
    end

    it 'tries to add an enrollee that already existss' do  
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person_2.authority_member_id)
      policy.enrollees.create(m_id:person_2.authority_member_id, rel_code:"self")

      expect(policy.enrollees.where(m_id: person_2.authority_member_id).count).to eq(1)
    end
  end
end