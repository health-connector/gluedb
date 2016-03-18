require "rails_helper"

describe ChangeSets::PersonNameChangeSet do

  describe "with an updated name" do
    let(:person) { instance_double("::Person", current_name) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", {:hbx_member_id => hbx_member_id}.merge(name_attributes)) } 
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double("::Services::CvPublisher") }

    let(:name_attributes) {
      {
        "name_first" => "Testing",
        "name_last" => "Errorsman",
        "name_middle" => "For",
        "name_pfx" => "Dr.",
        "name_sfx" => nil
      }
    }

    let(:current_name) {
        {
          :name_pfx => nil,
          :name_first => "Testing",
          :name_middle => "For",
          :name_last => "Errorsman",
          :name_sfx => "MD"
        }
    }

    let(:old_name_values) {
      {   "member_id"=>"some random member id wahtever",
          "name_sfx"=>"MD",
          "name_first" => "Testing",
          "name_last" => "Errorsman"
      }
    }
    subject { ChangeSets::PersonNameChangeSet.new }

    before :each do
      allow(person).to receive(:update_attributes).with(name_attributes).and_return(update_result)
    end

    describe "with an invalid new name" do
      let(:update_result) { false }
      it "should fail to process the update" do
        expect(subject.perform_update(person, person_resource, policies_to_notify)).to eq false
      end
    end

    describe "with a valid new name" do
      let(:update_result) { true }
      before :each do
        allow(::CanonicalVocabulary::IdInfoSerializer).to receive(:new).with(
          policy_to_notify, "change", "change_in_identifying_data_elements", [hbx_member_id], hbx_member_ids, [old_name_values]
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
