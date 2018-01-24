require "rails_helper"

class ChangeSets::SMTModuleTestHost
  include ::ChangeSets::SimpleMaintenanceTransmitter
end

describe ChangeSets::SimpleMaintenanceTransmitter do
  let(:operation) { double }
  let(:change_reason) { double }
  let(:cv2_reason) { double }
  let(:policy) { instance_double(Policy, :active_member_ids => active_member_ids, :is_shop? => true, :eg_id => eg_id) }
  let(:policies_to_notify) { [policy] }
  let(:active_member_ids) { ["member id 1", "member id 2"] }
  let(:eg_id) { double }

  subject { ::ChangeSets::SMTModuleTestHost.new }

  context "when the changed member is not an active member" do
    let(:member_id) { "member id 3" }

    it "does not publish" do
      expect(::BusinessProcesses::AffectedMember).not_to receive(:new)
      subject.notify_policies(operation, change_reason, member_id, policies_to_notify, cv2_reason)
    end
  end

  context "when the changed member is an active member, on a shop policy" do
    let(:member_id) { "member id 2" }
    let(:affected_member) { instance_double(::BusinessProcesses::AffectedMember) }
    let(:identity_change_transmitter) { instance_double(::ChangeSets::IdentityChangeTransmitter) }
    let(:nfp_publisher) { instance_double(::Services::NfpPublisher) }
    let(:cv_serializer) { instance_double(::CanonicalVocabulary::MaintenanceSerializer) }
    let(:serialized_cv) { double }

    before(:each) do
      allow(::BusinessProcesses::AffectedMember).to receive(:new).with(
        {
          :policy => policy,
          :member_id => member_id
        }
      ).and_return(affected_member)
      allow(::ChangeSets::IdentityChangeTransmitter).to receive(:new).with(
        affected_member,
        policy,
        cv2_reason
      ).and_return(identity_change_transmitter)
      allow(identity_change_transmitter).to receive(:publish)
      allow(::CanonicalVocabulary::MaintenanceSerializer).to receive(:new).with(
        policy,
        operation,
        change_reason,
        [member_id],
        active_member_ids
      ).and_return(cv_serializer)
      allow(cv_serializer).to receive(:serialize).and_return(serialized_cv)
      allow(::Services::NfpPublisher).to receive(:new).and_return(nfp_publisher)
      allow(nfp_publisher).to receive(:publish).with(true, "#{eg_id}.xml", serialized_cv)
    end

    it "publishes the identity change" do
      expect(::ChangeSets::IdentityChangeTransmitter).to receive(:new).with(
        affected_member,
        policy,
        cv2_reason
      ).and_return(identity_change_transmitter)
      expect(identity_change_transmitter).to receive(:publish)
      subject.notify_policies(operation, change_reason, member_id, policies_to_notify, cv2_reason)
    end

    it "publishes the change to nfp" do
      expect(nfp_publisher).to receive(:publish).with(true, "#{eg_id}.xml", serialized_cv)
      subject.notify_policies(operation, change_reason, member_id, policies_to_notify, cv2_reason)
    end
  end
end
