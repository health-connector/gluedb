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
        issuer_profile_ids
        employer_id
        broker_id
      )
      
      fields.each do  |field_name|
         expect(PlanYear.fields.keys).to include(field_name)
      end
    end

    it 'should have issuer profile ids as an array' do 
      expect(plan_year.issuer_profile_ids.class).to eq(Array)
    end
  end
  
end
