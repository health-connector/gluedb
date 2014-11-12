require 'rails_helper'

describe CreatePerson do

  let(:request) do 
    {
      person: person,
      demographics: demographics
    }
  end
  let(:listener) { double }
  let(:member_id) { "193202" } 

  let(:person) do
    {
      :id => "193202",
      :name_first=>"Megan",
      :name_last => "Troy",
      :name_full=>"Megan Troy",
      :addresses => addresses,
      :phones => phones,
      :emails => emails
      # :relationships => relationships
    }
  end

  let(:phones) do 
    [ 
      { 
        :phone_type=>"home",
        :phone_number=>"202-631-3975"
      } 
    ]
  end

  let(:addresses) do 
    [
      {
        :address_type=>"home", 
        :address_1=>"1915 16th St NW", 
        :address_2=>"Unit 103",
        :city=>"Washington", 
        :state=>"district_of_columbia",
        :location_state_code=>"DC", 
        :zip=>"20009"
      }
    ]
  end

  let(:emails) do
    [
      {
        :email_type=>"home",
        :email_address=>"meganatroy@gmail.com"
      }
    ]
  end

  let(:demographics) do 
    {
      :ssn=>"226493330", 
      :gender=>"female", 
      :dob=>"19861121", 
      :ethnicity=>nil, 
      :race=>nil, 
      :birth_location=>nil, 
      :citizen_status=>"us_citizen", 
      :is_state_resident=>nil, 
      :is_incarcerated=>nil
    }
  end 

  # let(:relationships) do 
  #   [
  #     {
  #       :subject_individual=>{id=>'193202'}, 
  #       :relationship_uri=>"self", 
  #       :object_individual=>{id=>"12111198"}
  #     }
  #   ]
  # end

  context 'when first name and last name are empty' do
    let(:person) do
      {
        :id => "193202",
        :name_first=> nil,
        :name_last => nil,
      }
    end
    it 'should notify listener of the failure' do
      expect(listener).to receive(:invalid_person)
      expect(subject.validate(request, listener)).to be_false
    end
  end

  context "when gender missing" do
    let(:demographics) {{ :gender=> nil }} 

    it 'should notify listener of the failure' do
      expect(listener).to receive(:invalid_member)
      expect(subject.validate(request, listener)).to be_false
    end
  end
end