require 'rails_helper'

describe ApplicationGroupBuilder do

  let(:person_mapper){
    double();
  }

  let(:member){
    Member.new({:dob=>"", :death_date=>"",:ssn=>"", :gender=>"", :ethnicity=>"", :race=>"", :marital_status=>""})
  }

  let(:person){
    Person.new({:id=> "222", :members=>[member]})
  }

  let(:applicant_params){
    {is_primary_applicant:"true", applicant_id:"12333", person:person}
  }

  before(:each){
    @params = { e_case_id:'12345', submitted_date:'05052014'}
    @application_group_builder = ApplicationGroupBuilder.new(@params, person_mapper)
    @application_group = @application_group_builder.application_group
  }

  it 'initialized with 1)person_mapper, 2)params and creates a 3)household and a 4)irs group' do
    expect(@application_group.e_case_id).to eq('12345')
    expect(@application_group.households.size).to eq(1)
    expect(@application_group.irs_groups.size).to eq(1)
  end

=begin
  it 'adds an applicant' do
    @application_group_builder.add_applicant(applicant_params)
    expect(@application_group.applicants.size).to eq(1)
  end
=end

  it "saves successfully" do
    expect(@application_group.save!).to eq(true)
  end
end