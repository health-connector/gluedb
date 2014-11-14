require "rails_helper"

describe Listeners::NewEnrollmentListener do
  let(:responder) { double }
  let(:errors) { { :policies => [], :individuals => [] } }
  let(:success_information) { }
  let(:qualifying_reason) { double }
  
  subject { Listeners::NewEnrollmentListener.new(qualifying_reason, responder) }

  it "should notify the responder of failure" do
    expect(responder).to receive(:handle_failure).with(errors)
    subject.fail
  end

  it "should handle success" do
    expect(responder).to receive(:handle_success).with(qualifying_reason, [])
    subject.success
  end

  describe "which has a policy created" do
    let(:policy_id) { "abcde" }

    before(:each) do 
      subject.policy_created(policy_id)
    end

    it "should tell the listener about successfully creating policies" do
      expect(responder).to receive(:handle_success).with(qualifying_reason, [policy_id])
      subject.success
    end
  end
end
