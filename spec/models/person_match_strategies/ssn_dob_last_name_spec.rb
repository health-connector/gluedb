require 'rails_helper'

describe PersonMatchStrategies::SsnDobLastName do

  let(:provided_ssn) { "123456789" }
  let(:options) {
    {
        :ssn => provided_ssn,
        :name_last => last_name,
        :dob=> dob
    }
  }
  let(:last_name) { "Lastname" }
  let(:dob) {"1999-01-28 00:00:00 UTC"}

  let(:person1) { double(:name_first => "First Name", :name_last => "Last Name", :authority_member => member1) }
  let(:member1) { double }
  subject { PersonMatchStrategies::SsnDobLastName.new }

  before(:each) do
    allow(Person).to receive(:where).with({"members.dob"=>cast_dob(dob), "members.ssn"=>provided_ssn, "name_last"=>last_name}).and_return(matching_people)
  end

  let(:matching_people) { [person1] }

  it "should match the person and member" do
    expect(subject.match(options)).to eq([person1, member1])
  end

  it "should not match the person and member" do
    allow(Person).to receive(:where).with({"members.dob"=>cast_dob(dob), "members.ssn"=>provided_ssn, "name_last"=>last_name}).and_return(nil)
    #expect(subject.match(options)).to eq([nil, nil])
  end

  def cast_dob(dob)
    if dob.kind_of?(Date)
      return dob
    elsif dob.kind_of?(DateTime)
      return dob
    end
    Date.parse(dob)
  end
end