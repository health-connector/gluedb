require "rails_helper"

describe HandlePolicyNotification::ExtractPlanDetails do
  let(:hios_id) { "88889999888833" }
  let(:active_year) { "2017" }
  let(:policy_cv) { instance_double(Openhbx::Cv2::PlanLink, :id => hios_id, active_year: active_year) }

  let(:interaction_context) {
    OpenStruct.new({
      :policy_cv => policy_cv
    })
  }

  subject { HandlePolicyNotification::ExtractPlanDetails.call(interaction_context) }

  describe "given a policy element" do

    it "extracts hios_id" do
      expect(subject.policy_cv.id).to eq hios_id
    end

    it "extracts active_year" do
      expect(subject.policy_cv.active_year).to eq active_year
    end

  end

end
