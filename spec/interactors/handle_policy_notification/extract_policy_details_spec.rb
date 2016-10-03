require "rails_helper"

describe HandlePolicyNotification::ExtractPolicyDetails do

  subject { HandlePolicyNotification::ExtractPolicyDetails.call(interaction_context) }

  describe "given a policy element" do
    let(:enrollment_group_id) { "2938749827349723974" }
    let(:pre_amt_tot) { "290.13" }
    let(:tot_res_amt) { "123.13" }
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :premium_total_amount => pre_amt_tot, :total_responsible_amount => tot_res_amt) }
    let(:policy_cv) { instance_double(Openhbx::Cv2::Policy, :id => policy_id, :policy_enrollment => enrollment_element) }
    let(:policy_id) { "urn:openhbx:hbx:dc0:resources:v1:policy:hbx_id##{enrollment_group_id}" }

    let(:interaction_context) { 
      OpenStruct.new({
        :policy_cv => policy_cv
      })
    }

    it "extracts the enrollment group id" do
      expect(subject.policy_details.enrollment_group_id).to eq enrollment_group_id
    end

    it "extracts the pre_amt_tot" do
      expect(subject.policy_details.pre_amt_tot).to eq pre_amt_tot
    end

    it "extracts the tot_res_amt" do
      expect(subject.policy_details.tot_res_amt).to eq tot_res_amt
    end
  end
end
