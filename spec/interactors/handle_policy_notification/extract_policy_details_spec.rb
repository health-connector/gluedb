require "rails_helper"

describe HandlePolicyNotification::ExtractPolicyDetails do

  subject { HandlePolicyNotification::ExtractPolicyDetails.call(interaction_context) }

  describe "given a policy element" do
    let(:enrollment_group_id) { "2938749827349723974" }
    let(:policy_cv) { instance_double(Openhbx::Cv2::Policy, :id => policy_id) }
    let(:policy_id) { "urn:openhbx:hbx:dc0:resources:v1:policy:hbx_id##{enrollment_group_id}" }


    let(:interaction_context) { 
      OpenStruct.new({
        :policy_cv => policy_cv
      })
    }

    it "extracts the enrollment group id" do
      expect(subject.policy_details.enrollment_group_id).to eq enrollment_group_id
    end
  end
end
