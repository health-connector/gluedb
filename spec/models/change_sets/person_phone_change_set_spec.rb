require "rails_helper"

describe ChangeSets::PersonPhoneChangeSet do
  let(:address_update_result) { true }

  describe "with a phone to wipe" do
    let(:person) { instance_double("::Person", :save => address_update_result) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :phones => [], :hbx_member_id => hbx_member_id) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double("::Services::CvPublisher") }
    let(:phone_kind) { "home" }
    subject { ChangeSets::PersonPhoneChangeSet.new(phone_kind) }

    before :each do
      allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
        policy_to_notify, "change", "personnel_data", [hbx_member_id], hbx_member_ids
      ).and_return(policy_serializer)
      allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
      allow(::Services::CvPublisher).to receive(:new).and_return(cv_publisher)
    end

    it "should update the person" do
      allow(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
      expect(person).to receive(:remove_phone_of).with(phone_kind)
      expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq true
    end

    it "should send out policy notifications" do
      expect(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
      allow(person).to receive(:remove_phone_of).with(phone_kind)
      subject.perform_update(person, person_resource, policies_to_notify)
    end

  end

  describe "with an updated phone" do
    let(:person) { instance_double("::Person", :save => address_update_result) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :phones => [updated_phone_resource], :hbx_member_id => hbx_member_id) }
    let(:updated_phone_resource) { double(:to_hash => {:phone_type => phone_kind}, :phone_type => phone_kind) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double("::Services::CvPublisher") }
    let(:phone_kind) { "home" }
    let(:new_phone) { double }
    subject { ChangeSets::PersonPhoneChangeSet.new(phone_kind) }

    before :each do
      allow(Phone).to receive(:new).with({:phone_type => phone_kind}).and_return(new_phone)
      allow(person).to receive(:set_phone).with(new_phone)
    end

    describe "updating a home phone" do
      let(:phone_kind) { "home" }

      describe "with an invalid new phone" do
        let(:address_update_result) { false }
        it "should fail to process the update" do
          expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq false
        end
      end

      describe "with a valid new phone" do
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

    describe "updating a work phone" do
      let(:phone_kind) { "work" }

      describe "with an invalid new phone" do
        let(:address_update_result) { false }
        it "should fail to process the update" do
          expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq false
        end
      end

      describe "with a valid new phone" do
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

  describe "#applicable?" do
    let(:phone_kind) { "home" }
    let(:changeset) { ChangeSets::PersonPhoneChangeSet.new(phone_kind) }
    let(:person_phone) { instance_double("::Phone", :phone_type => phone_kind) }
    let(:person_resource_phone) { double(:phone_kind => phone_kind ) }

    subject { changeset.applicable?(person, person_resource) }

    describe "given a person with a home phone and an update to remove it" do
      let(:person) { instance_double("::Person", :phones => [person_phone]) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :phones => []) }

      before(:each) do
        allow(person_phone).to receive(:match).with(nil).and_return(false)
      end

      it { is_expected.to be_truthy }
    end

    describe "given a person with no home phone and an update to add one" do
      let(:person) { instance_double("::Person", :phones => []) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :phones => [person_resource_phone]) }

      it { is_expected.to be_truthy }
    end

    describe "given a person with no home phone and an update which does not contain one" do
      let(:person) { instance_double("::Person", :phones => []) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :phones => []) }

      it { is_expected.to be_falsey }
    end

    describe "given a person update with a different home phone from the existing record" do
      let(:person) { instance_double("::Person", :phones => [person_phone]) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :phones => [person_resource_phone]) }

      before(:each) do
        allow(person_phone).to receive(:match).with(person_resource_phone).and_return(false)
      end

      it { is_expected.to be_truthy }
    end

    describe "given a person update with the same home email as the existing record" do
      let(:person) { instance_double("::Person", :phones => [person_phone]) }
      let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :phones => [person_resource_phone]) }

      before(:each) do
        allow(person_phone).to receive(:match).with(person_resource_phone).and_return(true)
      end

      it { is_expected.to be_falsey }
    end

  end
end
