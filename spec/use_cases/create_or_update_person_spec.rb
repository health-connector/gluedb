require "rails_helper"

describe CreateOrUpdatePerson do

  let (:person_finder) { double }
  let (:person_factory) { double }
  let (:member_factory) { double }
  let (:person_props) { { :name_first => "ABDCEDsafef" } }
  let (:request) { member_props.merge(person_props) }
  let (:listener) { double }

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
end
