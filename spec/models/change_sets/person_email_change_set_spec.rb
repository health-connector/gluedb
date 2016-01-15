require "rails_helper"

describe ChangeSets::PersonEmailChangeSet do
  let(:address_update_result) { true }

  describe "with an email to wipe" do
    let(:person) { instance_double("::Person", :save => address_update_result) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :emails => [], :hbx_member_id => hbx_member_id) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double("::Services::CvPublisher") }
    let(:email_kind) { "home" }
    subject { ChangeSets::PersonEmailChangeSet.new(email_kind) }

    before :each do
      allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
        policy_to_notify, "change", "personnel_data", [hbx_member_id], hbx_member_ids
      ).and_return(policy_serializer)
      allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
      allow(::Services::CvPublisher).to receive(:new).and_return(cv_publisher)
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
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double("::Services::CvPublisher") }
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

        before :each do
          allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
            policy_to_notify, "change", "personnel_data", [hbx_member_id], hbx_member_ids
          ).and_return(policy_serializer)
          allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
          allow(::Services::CvPublisher).to receive(:new).and_return(cv_publisher)
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

      describe "with an invalid new email" do
        let(:address_update_result) { false }
        it "should fail to process the update" do
          expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq false
        end
      end

      describe "with a valid new email" do
        let(:address_update_result) { true }

        before :each do
          allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
            policy_to_notify, "change", "personnel_data", [hbx_member_id], hbx_member_ids
          ).and_return(policy_serializer)
          allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
          allow(::Services::CvPublisher).to receive(:new).and_return(cv_publisher)
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
  end
end
