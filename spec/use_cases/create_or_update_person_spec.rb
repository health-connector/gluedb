require "rails_helper"

describe CreateOrUpdatePerson do

  let(:person_finder) { double }
  let(:person_factory) { double }
  let(:member_factory) { double }
  let(:person_props) { { :name_first => "ABDCEDsafef" } }
  let(:request) { member_props.merge(person_props).merge(other_props) }
  let(:listener) { double }

  let(:other_props) {
    {
      :addresses => addresses,
      :emails => emails, 
      :phones => phones
    } 
  }

  let(:addresses) { [] }
  let(:emails) { [] }
  let(:phones) { [] }

  let(:member_props) { { :dob => dob, :ssn => ssn, :hbx_member_id => hbx_member_id, :gender => gender } }

  let(:dob) { double }
  let(:ssn) { double }
  let(:gender) { double }
  let(:hbx_member_id) { double }

  subject { CreateOrUpdatePerson.new(person_finder, person_factory, member_factory) }

  describe "validating the request" do

    let(:new_person) { double }
    let(:errors) { double }
    let(:errors_hash) { double }

    before(:each) do
      allow(person_finder).to receive(:find_person_and_member).with(request).and_return([nil, nil])
      allow(person_factory).to receive(:new).with(request).and_return(new_person)
    end

    describe "and the person is invalid" do
      before(:each) do
        allow(new_person).to receive(:valid?).and_return(false)
        allow(new_person).to receive(:errors).and_return(errors)
        allow(errors).to receive(:to_hash).and_return(errors_hash)
      end

      it "should notify the listener of failure" do
        expect(listener).to receive(:invalid_person).with(errors_hash)
        expect(subject.validate(request, listener)).to be_falsey
      end
    end

    describe "and the person is valid" do
      let(:new_member) { double }

      before(:each) do 
        allow(new_person).to receive(:valid?).and_return(true)
        allow(member_factory).to receive(:new).with(request).and_return(new_member)
      end

      describe "and the member is invalid" do
        before(:each) do
          allow(new_member).to receive(:valid?).and_return(false)
          allow(new_member).to receive(:errors).and_return(errors)
          allow(errors).to receive(:to_hash).and_return(errors_hash)
        end

        it "should notify the listener of failure" do
          expect(listener).to receive(:invalid_member).with(errors_hash)
          expect(subject.validate(request, listener)).to be_falsey
        end
      end

      describe "and the member is valid" do
        before(:each) do
          allow(new_member).to receive(:valid?).and_return(true)
        end

        it "should validate" do
          expect(subject.validate(request, listener)).to be_truthy
        end
      end


      describe "when a match error occurs" do
        let(:person_match_error_message) { "Some matching failure." }

        it "should notify the listener" do
          allow(person_finder).to receive(:find_person_and_member).with(request).and_raise(PersonMatchStrategies::AmbiguiousMatchError.new(person_match_error_message))
          expect(listener).to receive(:person_match_error).with(person_match_error_message)
          expect(subject.validate(request, listener)).to be_falsey
        end
      end

    end
  end

  describe "completing the transaction" do
    describe "when person does not exist" do
      let(:new_person) { double }
      let(:new_member) { double }
      let(:members) { double }

      before(:each) do
        allow(person_finder).to receive(:find_person_and_member).with(request).and_return([nil, nil])
      end

      it "should create a new person and member, and notify the listener" do
        allow(person_factory).to receive(:new).with(request).and_return(new_person)
        allow(member_factory).to receive(:new).with(member_props).and_return(new_member)
        expect(new_person).to receive(:members).and_return(members)
        expect(members).to receive(:<<).with(new_member)
        expect(new_person).to receive(:authority_member_id=).with(hbx_member_id)
        expect(new_person).to receive(:save!)
        expect(listener).to receive(:register_person).with(hbx_member_id, new_person, new_member)
        subject.commit(request, listener)
      end
    end

    describe "when person exists without member" do
      let(:person) { double }
      let(:new_member) { double }
      let(:members) { double }
      before(:each) do
        allow(person_finder).to receive(:find_person_and_member).with(request).and_return([person, nil])
      end

      it "should update person, create member, and notify listener" do
        expect(person).to receive(:assign_attributes).with(person_props)
        allow(member_factory).to receive(:new).with(member_props).and_return(new_member)
        expect(person).to receive(:members).and_return(members)
        expect(members).to receive(:<<).with(new_member)
        expect(person).to receive(:authority_member_id=).with(hbx_member_id)
        expect(person).to receive(:save!)
        expect(listener).to receive(:register_person).with(hbx_member_id, person, new_member)
        subject.commit(request, listener)
      end
    end

    describe "when person and member exist" do
      let(:person) { double }
      let(:member) { double }
      let(:clean_member_props) { { :dob => dob, :ssn => ssn, :gender => gender } }
      before(:each) do
        allow(person_finder).to receive(:find_person_and_member).with(request).and_return([person, member])
      end

      it "should update person, update member, and notify listener" do
        expect(person).to receive(:assign_attributes).with(person_props)
        expect(member).to receive(:update_attributes).with(clean_member_props)
        expect(person).to receive(:save!)
        expect(listener).to receive(:register_person).with(hbx_member_id, person, member)
        subject.commit(request, listener)
      end
    end
  end 
end
