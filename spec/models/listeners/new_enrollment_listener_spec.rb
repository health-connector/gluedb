require "rails_helper"

describe Listeners::NewEnrollmentListener do
  let(:responder) { double }
  let(:errors) { { :policies => [], :individuals => [] } }
  let(:success_information) { }
  let(:other_details) { double }
  
  subject { Listeners::NewEnrollmentListener.new(other_details, responder) }

  it "should notify the responder of failure" do
    expect(responder).to receive(:handle_failure).with(other_details, errors)
    subject.fail
  end

  it "should handle success" do
    expect(responder).to receive(:handle_success).with(other_details, [], [])
    subject.success
  end

  describe "which has a policy created" do
    let(:policy_id) { "abcde" }
    let(:old_policy_id) { "abcdef" }

    before(:each) do 
      subject.policy_created(policy_id)
      subject.policy_canceled(old_policy_id)
    end

    it "should tell the listener about successfully creating policies" do
      expect(responder).to receive(:handle_success).with(other_details, [policy_id], [old_policy_id])
      subject.success
    end
  end
end
