require "rails_helper"

describe ChangeSets::PersonSsnChangeSet do

  describe "with an updated name" do
    let(:member) { instance_double("::Member", :ssn => old_ssn) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :hbx_member_id => hbx_member_id, :ssn => new_ssn) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double("::Services::CvPublisher") }

    let(:old_ssn) { "999999999" }

    let(:new_ssn) { "111111111" }

    let(:old_ssn_values) {
      {"member_id"=>"some random member id wahtever", "ssn"=>old_ssn }
    }
    subject { ChangeSets::PersonSsnChangeSet.new }

    before :each do
      allow(member).to receive(:update_attributes).with({"ssn" => new_ssn}).and_return(update_result)
    end

    describe "with an invalid new ssn" do
      let(:update_result) { false }
      it "should fail to process the update" do
        expect(subject.perform_update(member, person_resource, policies_to_notify)).to eq false
      end
    end

    describe "with a valid new ssn" do
      let(:update_result) { true }
      before :each do
        allow(::CanonicalVocabulary::IdInfoSerializer).to receive(:new).with(
          policy_to_notify, "change", "change_in_identifying_data_elements", [hbx_member_id], hbx_member_ids, [old_ssn_values]
        ).and_return(policy_serializer)
        allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
        allow(::Services::CvPublisher).to receive(:new).and_return(cv_publisher)
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
end
