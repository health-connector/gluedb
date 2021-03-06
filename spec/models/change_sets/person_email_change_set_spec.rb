require "rails_helper"

describe ChangeSets::PersonEmailChangeSet do
  let(:address_update_result) { true }

  describe "with an email to wipe" do
    let(:person) { instance_double("::Person", :save => address_update_result) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => [], :hbx_member_id => hbx_member_id) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids, :is_shop? => true, :enrollees => nil) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double(::Services::NfpPublisher) }
    let(:email_kind) { "home" }
    let(:identity_change_transmitter) { instance_double(::ChangeSets::IdentityChangeTransmitter, :publish => nil) }
    let(:affected_member) { instance_double(::BusinessProcesses::AffectedMember) }
    subject { ChangeSets::PersonEmailChangeSet.new(email_kind) }

    before :each do
      allow(::BusinessProcesses::AffectedMember).to receive(:new).with(
        { :policy => policy_to_notify, :member_id => hbx_member_id }
      ).and_return(affected_member)
      allow(::ChangeSets::IdentityChangeTransmitter).to receive(:new).with(
        affected_member,
        policy_to_notify,
        "urn:openhbx:terms:v1:enrollment#change_member_communication_numbers"
      ).and_return(identity_change_transmitter)
      allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
        policy_to_notify, "change", "personnel_data", [hbx_member_id], hbx_member_ids
      ).and_return(policy_serializer)
      allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
      allow(::Services::NfpPublisher).to receive(:new).and_return(cv_publisher)
    end

    it "should update the person" do
      allow(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
      expect(person).to receive(:remove_email_of).with(email_kind)
      expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq true
    end

    it "should send out policy notifications" do
      expect(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
      allow(person).to receive(:remove_email_of).with(email_kind)
      subject.perform_update(person, person_resource, policies_to_notify)
    end

  end

  describe "with an updated email" do
    let(:person) { instance_double("::Person", :save => address_update_result) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => [updated_email_resource], :hbx_member_id => hbx_member_id) }
    let(:updated_email_resource) { double(:to_hash => {:email_type => email_kind}, :email_type => email_kind) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids, :is_shop? => true) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double(::Services::NfpPublisher) }
    let(:email_kind) { "home" }
    let(:new_email) { double }
    subject { ChangeSets::PersonEmailChangeSet.new(email_kind) }

    before :each do
      allow(Email).to receive(:new).with({:email_type => email_kind}).and_return(new_email)
      allow(person).to receive(:set_email).with(new_email)
    end

    describe "updating a home email" do
      let(:email_kind) { "home" }

      describe "with an invalid new email" do
        let(:address_update_result) { false }
        it "should fail to process the update" do
          expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq false
        end
      end

      describe "with a valid new email" do
        let(:address_update_result) { true }
        let(:identity_change_transmitter) { instance_double(::ChangeSets::IdentityChangeTransmitter, :publish => nil) }
        let(:affected_member) { instance_double(::BusinessProcesses::AffectedMember) }

        before :each do
          allow(::BusinessProcesses::AffectedMember).to receive(:new).with(
            { :policy => policy_to_notify, :member_id => hbx_member_id }
          ).and_return(affected_member)
          allow(::ChangeSets::IdentityChangeTransmitter).to receive(:new).with(
            affected_member,
            policy_to_notify,
            "urn:openhbx:terms:v1:enrollment#change_member_communication_numbers"
          ).and_return(identity_change_transmitter)
          allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
            policy_to_notify, "change", "personnel_data", [hbx_member_id], hbx_member_ids
          ).and_return(policy_serializer)
          allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
          allow(::Services::NfpPublisher).to receive(:new).and_return(cv_publisher)
        end

        it "should update the person" do
          allow(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
          expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq true
        end

        it "should send out policy notifications" do
          expect(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
          subject.perform_update(person, person_resource, policies_to_notify)
        end
      end
    end

    describe "updating a work email" do
      let(:email_kind) { "work" }
      let(:identity_change_transmitter) { instance_double(::ChangeSets::IdentityChangeTransmitter, :publish => nil) }
      let(:affected_member) { instance_double(::BusinessProcesses::AffectedMember) }

      describe "with an invalid new email" do
        let(:address_update_result) { false }
        it "should fail to process the update" do
          expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq false
        end
      end

      describe "with a valid new email" do
        let(:address_update_result) { true }

        before :each do
          allow(::BusinessProcesses::AffectedMember).to receive(:new).with(
            { :policy => policy_to_notify, :member_id => hbx_member_id }
          ).and_return(affected_member)
          allow(::ChangeSets::IdentityChangeTransmitter).to receive(:new).with(
            affected_member,
            policy_to_notify,
            "urn:openhbx:terms:v1:enrollment#change_member_communication_numbers"
          ).and_return(identity_change_transmitter)
          allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
            policy_to_notify, "change", "personnel_data", [hbx_member_id], hbx_member_ids
          ).and_return(policy_serializer)
          allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
          allow(::Services::NfpPublisher).to receive(:new).and_return(cv_publisher)
        end

        it "should update the person" do
          expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq true
        end

        it "should not send out policy notifications" do
          expect(cv_publisher).not_to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
          subject.perform_update(person, person_resource, policies_to_notify)
        end
      end
    end
  end

  describe "#applicable?" do
    let(:email_kind) { "home" }
    let(:changeset) { ChangeSets::PersonEmailChangeSet.new(email_kind) }
    let(:person_email) { instance_double("::Email", :email_type => email_kind) }
    let(:person_resource_email) { double(:email_kind => email_kind ) }

    subject { changeset.applicable?(person, person_resource) }

    describe "given a person with a home email and an update to remove it" do
      let(:person) { instance_double("::Person", :emails => [person_email]) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => []) }

      before(:each) do
        allow(person_email).to receive(:match).with(nil).and_return(false)
      end

      it { is_expected.to be_truthy }
    end

    describe "given a person with no home email and an update to add one" do
      let(:person) { instance_double("::Person", :emails => []) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => [person_resource_email]) }

      it { is_expected.to be_truthy }
    end

    describe "given a person with no home email and an update which does not contain one" do
      let(:person) { instance_double("::Person", :emails => []) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => []) }

      it { is_expected.to be_falsey }
    end

    describe "given a person update with a different home email from the existing record" do
      let(:person) { instance_double("::Person", :emails => [person_email]) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => [person_resource_email]) }

      before(:each) do
        allow(person_email).to receive(:match).with(person_resource_email).and_return(false)
      end

      it { is_expected.to be_truthy }
    end

    describe "given a person update with the same home email as the existing record" do
      let(:person) { instance_double("::Person", :emails => [person_email]) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => [person_resource_email]) }

      before(:each) do
        allow(person_email).to receive(:match).with(person_resource_email).and_return(true)
      end

      it { is_expected.to be_falsey }
    end

  end
end
