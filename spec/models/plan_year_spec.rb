require 'rails_helper'

describe PlanYear do
  describe "#PlanYear" do 
    let(:plan_year) {FactoryGirl.create(:plan_year)}

    it { should belong_to :employer }
    it { should belong_to :broker }

    it 'should have the expected fields' do 
      fields = %w(
        _id 
        created_at 
        updated_at 
        start_date 
        end_date
        open_enrollment_start
        open_enrollment_end 
        fte_count
        pte_count
        issuer_ids
        employer_id
        broker_id
      )
      
      fields.each do  |field_name|
         expect(PlanYear.fields.keys).to include(field_name)
      end
    end
  end

  describe 'associated with issuers' do
    let(:issuer1) {Carrier.new} 
    let(:issuer2) {Carrier.new} 

    before(:each) do 
     subject.issuers = [issuer1, issuer2]
    end

    it 'is associated with issuer 1' do
      expect(subject.issuer_ids).to include(issuer1.id)
    end

    it 'is associated with issuer 2' do 
      expect(subject.issuer_ids).to include(issuer2.id)
    end
  end
  
end
