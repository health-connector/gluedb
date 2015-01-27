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
    @params = { e_case_id:'12345', submitted_at:DateTime.now}
    @application_group_builder = ApplicationGroupBuilder.new(@params, person_mapper)
    @family = @application_group_builder.family
  }


=begin
  it 'adds an applicant' do
    @application_group_builder.add_applicant(applicant_params)
    expect(@application_group.family_members.size).to eq(1)
  end
=end

  it "builds a valid family object" do
    expect(@family.class.name).to eq('Family')
    expect(@family.valid?).to be_true

  end

  it "saves successfully" do
    expect(@family.save!).to eq(true)
  end
end