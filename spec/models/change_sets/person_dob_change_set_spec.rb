require "rails_helper"

describe ChangeSets::PersonDobChangeSet do

  describe "with an updated dob" do
    let(:member) { instance_double("::Member", :dob => old_dob) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :hbx_member_id => hbx_member_id, :dob => new_dob) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids, :is_shop? => true, :enrollees => []) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double(::Services::NfpPublisher) }
    let(:identity_change_transmitter) { instance_double(::ChangeSets::IdentityChangeTransmitter, :publish => nil) }
    let(:affected_member) { instance_double(::BusinessProcesses::AffectedMember) }

    let(:old_dob) { "01/01/1960" }

    let(:new_dob) { "01/01/1970" }

    let(:old_dob_values) {
      {"member_id"=>"some random member id wahtever", "dob" => old_dob}
    }
    subject { ChangeSets::PersonDobChangeSet.new }

    before :each do
      allow(::BusinessProcesses::AffectedMember).to receive(:new).with(
       { :policy => policy_to_notify, "member_id" => hbx_member_id, "dob" => old_dob }
      ).and_return(affected_member)
      allow(::ChangeSets::IdentityChangeTransmitter).to receive(:new).with(
        affected_member,
        policy_to_notify,
        "urn:openhbx:terms:v1:enrollment#change_member_name_or_demographic"
      ).and_return(identity_change_transmitter)
      allow(member).to receive(:update_attributes).with({"dob" => new_dob}).and_return(update_result)
      allow(subject).to receive(:update_enrollments_for).and_return true
    end

    describe "with an invalid new dob" do
      let(:update_result) { false }
      it "should fail to process the update" do
        expect(subject.perform_update(member, person_resource, policies_to_notify)).to eq false
      end
    end

    describe "with a valid new dob" do
      let(:update_result) { true }
      before :each do
        allow(::CanonicalVocabulary::IdInfoSerializer).to receive(:new).with(
          policy_to_notify, "change", "change_in_identifying_data_elements", [hbx_member_id], hbx_member_ids, [old_dob_values]
        ).and_return(policy_serializer)
        allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
        allow(::Services::NfpPublisher).to receive(:new).and_return(cv_publisher)
      end

      it "should update the person" do
        allow(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
        expect(subject.perform_update(member, person_resource, policies_to_notify)).to eq true
      end

      it "should send out policy notifications" do
        expect(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
        subject.perform_update(member, person_resource, policies_to_notify)
      end
    end
  end

  describe 'test' do
    let(:member) { FactoryGirl.build :member }
    let(:person) { FactoryGirl.create :person, members: [ member ] }

    let(:example_data) {
      o_file = File.open(File.join(Rails.root, "spec/data/remote_resources/individual.xml"))
      data = o_file.read
      o_file.close
      data
    }

    let(:remote_resource) { RemoteResources::IndividualResource.parse(example_data, :single => true) }
    let(:changeset) { ::ChangeSets::IndividualChangeSet.new(remote_resource) }

    before :each do
      allow(person).to receive(:members).and_return(double(detect: member))
      allow(::Queries::PersonByHbxIdQuery).to receive(:new).with("18941339").and_return(double(execute: person))
      allow(changeset).to receive(:home_address_changed?).and_return(false)
      allow(changeset).to receive(:mailing_address_changed?).and_return(false)
      allow(changeset).to receive(:names_changed?).and_return(false)
      allow(changeset).to receive(:ssn_changed?).and_return(false)
      allow(changeset).to receive(:gender_changed?).and_return(false)
      allow(changeset).to receive(:home_email_changed?).and_return(false)
      allow(changeset).to receive(:work_email_changed?).and_return(false)
      allow(changeset).to receive(:home_phone_changed?).and_return(false)
      allow(changeset).to receive(:work_phone_changed?).and_return(false)
      allow(changeset).to receive(:mobile_phone_changed?).and_return(false)
      allow(Amqp::Requestor).to receive(:default).and_return(instance_double(Amqp::Requestor))
    end

    it 'should work' do
      p changeset.change_collection
      expect(changeset.dob_changed?).to be_truthy
    end

    it 'should work too' do
      expect(changeset.process_first_edi_change).to be_truthy
    end
  end

  describe '#update_enrollments_for' do
    let(:policy) { FactoryGirl.create :policy }
    let(:dob_changeset) { ::ChangeSets::PersonDobChangeSet.new }
    let(:member) { FactoryGirl.build :member }
    let(:person) { FactoryGirl.create :person, members: [ member ] }

    before :each do
      allow(Amqp::Requestor).to receive(:default).and_return(instance_double(Amqp::Requestor))
    end

    it 'updates policies' do
      expect(dob_changeset.update_enrollments_for([policy])).to be_truthy
    end
  end
end
