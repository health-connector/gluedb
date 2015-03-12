require 'rails_helper'

describe PersonMatchStrategies::SsnDobName do

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
  subject { PersonMatchStrategies::SsnDobName.new }

  before(:each) do
    allow(Person).to receive(:where).with({"members.dob"=>cast_dob(dob), "members.ssn"=>provided_ssn, "name_last"=>last_name}).and_return(matching_people)
  end

  let(:matching_people) { [person1] }

  it "should match the person and member" do
    #expect(subject.match(options)).to eq([person1, member1])
  end

  it "should not match the person and member" do
    #allow(Person).to receive(:where).with({"members.dob"=>cast_dob(dob), "members.ssn"=>provided_ssn, "name_last"=>last_name}).and_return(nil)
    #expect(subject.match(options)).to eq([nil, nil])
  end

  it "should normalize names" do
      expect(subject.normalize("nice-name")).to eq("nicename")
      expect(subject.normalize("nice name")).to eq("nicename")
      expect(subject.normalize("nice-name jr")).to eq("nicename")
      expect(subject.normalize("nice-name jr.")).to eq("nicename")
      expect(subject.normalize("nice-name ii.")).to eq("nicename")
      expect(subject.normalize("nice jr name.")).to eq("nicejrname")
      expect(subject.normalize("nice'name$")).to eq("nicename")
  end

  it "matches full names" do
    expect(subject.full_name_match?("sama Tara john","sama Tara John jr")).to be_truthy
  end

  it "matches when one name is contained in another" do
    expect(subject.last_name_subset_match?("saba-ram","ram")).to be_truthy
    expect(subject.last_name_subset_match?("landry nzigou bissielou","nzigou")).to be_truthy
    expect(subject.last_name_subset_match?("ballantine "," elizabeth ballantine")).to be_truthy
    expect(subject.last_name_subset_match?("ballantine jr."," elizabeth ballantine jr")).to be_truthy
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