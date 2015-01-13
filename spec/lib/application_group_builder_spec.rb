require 'rails_helper'

describe ApplicationGroupBuilder do

  before(:all){
    person_mapper = PersonMapper.new
    @params = { e_case_id:'12345', submitted_date:'05052014'}
    @application_group = ApplicationGroupBuilder.new(@params, person_mapper).application_group
  }

  it 'initialized with person_mapper, params and creates a household' do
    expect(@application_group.e_case_id).to eq('12345')
    expect(@application_group.households.size).to eq(1)
  end

  it "adds an applicant" do

  end
end