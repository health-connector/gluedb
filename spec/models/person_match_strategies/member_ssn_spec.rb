require 'rails_helper'

describe PersonMatchStrategies::MemberSsn do
  let(:provided_ssn) { "123456789" }
  let(:options) {
      { 
        :ssn => provided_ssn,
        :name_first => first_name,
        :name_last => last_name
      }
  }
  let(:first_name) { "First Name" }
  let(:last_name) { "Last Name" }

  let(:person1) { double(:name_first => "First Name", :name_last => "Last Name", :authority_member => member1) }
  let(:member1) { double }
  subject { PersonMatchStrategies::MemberSsn.new }

  before(:each) do
    allow(Person).to receive(:where).with({"members.ssn" => provided_ssn}).and_return(matching_people)
  end

  describe "when finding a single person with a matching ssn" do
    let(:matching_people) { [person1] }

    describe "with a matching first and last name" do
      it "should match the person and member" do
        expect(subject.match(options)).to eq([person1, member1])
      end
    end

    describe "with a mismatched first name" do
      let(:first_name) { "TOTAL MISMATCH DOOOOOOOOD" }

      it "should raise an error" do
        expect { subject.match(options) }.to raise_error(PersonMatchStrategies::AmbiguousMatchError)
      end
    end

    describe "with a mismatched last name" do
      let(:last_name) { "TOTAL MISMATCH DOOOOOOOOD" }

      it "should raise an error" do
        expect { subject.match(options) }.to raise_error(PersonMatchStrategies::AmbiguousMatchError)
      end
    end
  end
end
