require 'rails_helper'

describe ::ChangeSets::IndividualChangeSet do
  let(:remote_resource) { double(:exists? => remote_resource_exists, :record => existing_record) }

  let(:changeset) { ::ChangeSets::IndividualChangeSet.new(remote_resource) }
  context "with a record that already exists" do
    describe "#individual_exists?" do
      let(:remote_resource_exists) { false }
      let(:existing_record) { nil }
      subject { changeset.individual_exists? }
      it { is_expected.to be_falsey }
    end

    describe "#create_individual_resource" do
      let(:created_person) { double(:save => create_person_result) }
      let(:remote_resource_exists) { false }
      let(:existing_record) { nil }
      let(:member_hash) do
        {}
      end

      let(:person_parameters) do
        { 
          :members => [created_member],
          :addresses => [],
          :phones => [],
          :emails => []
        }
      end

      let(:created_member) { double }

      before :each do
        allow(remote_resource).to receive(:to_hash).and_return(person_parameters)
        allow(remote_resource).to receive(:member_hash).and_return(member_hash)
        allow(remote_resource).to receive(:addresses).and_return([])
        allow(remote_resource).to receive(:phones).and_return([])
        allow(remote_resource).to receive(:emails).and_return([])
        allow(Member).to receive(:new).with(member_hash).and_return(created_member)
        allow(Person).to receive(:new).with(hash_including(person_parameters)).and_return(created_person)
      end

      subject { changeset.create_individual_resource }
      context "with valid data" do
        let(:create_person_result) { true }

        it { is_expected.to eq(create_person_result) }

        it "initializes the person, using attributes from the remote resource" do
          expect(Person).to receive(:new).with(person_parameters)
          subject
        end

        it "saves the new person" do
          expect(created_person).to receive(:save)
          subject
        end
      end

      context "with invalid data" do
        let(:error_messages) { double }
        let(:create_person_result) { false }
        let(:record_error_proxy) { double(:full_messages => error_messages) }

        before :each do
          allow(created_person).to receive(:errors).and_return(record_error_proxy)
        end

        it { is_expected.to eq(create_person_result) }
        it "initializes the person, using attributes from the remote resource" do
          expect(Person).to receive(:new).with(person_parameters)
          subject
        end
        it "attempts to save the new person" do
          expect(created_person).to receive(:save)
          subject
        end
        it "populates the validation errors" do
          subject
          expect(changeset.full_error_messages).to eq(error_messages)
        end
      end
    end
  end

  context "with a record that does exist" do
    describe "#individual_exists?" do
      let(:remote_resource_exists) { true }
      let(:existing_record) { double }
      subject { changeset.individual_exists? }
      it { is_expected.to be_truthy }
    end
  end
end
