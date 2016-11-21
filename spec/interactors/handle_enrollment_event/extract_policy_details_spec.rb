require "rails_helper"

describe HandleEnrollmentEvent::ExtractPolicyDetails do
  let(:enrollment_group_id) { "2938749827349723974" }
  let(:pre_amt_tot) { "290.13" }
  let(:tot_res_amt) { "123.13" }
  let(:tot_emp_res_amt) { "234.30" }
  let(:transaction_id) { "123455463456345634563456" }
  let(:enrollment_event_cv) { instance_double(Openhbx::Cv2::EnrollmentEvent, event: enrollment_event_event) }
  let(:enrollment_event_event) { instance_double(Openhbx::Cv2::EnrollmentEventEvent, body: enrollment_event_body) }
  let(:enrollment_event_body) { instance_double(Openhbx::Cv2::EnrollmentEventBody, enrollment: enrollment, transaction_id: transaction_id) }
  let(:enrollment) { instance_double(Openhbx::Cv2::Enrollment, policy: policy_cv) }
  let(:policy_cv) { instance_double(Openhbx::Cv2::Policy, :id => policy_id, :policy_enrollment => enrollment_element) }
  let(:shop_enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollmentShopMarket, :total_employer_responsible_amount => tot_emp_res_amt) }
  let(:individual_enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollmentIndividualMarket, :is_carrier_to_bill => "is_carrier_to_bill", elected_aptc_percent: "elected_aptc_percent", applied_aptc_amount: "applied_aptc_amount", allocated_aptc_amount: "allocated_aptc_amount") }
  let(:raw_event_xml) { "Some event xml" }

  let(:interaction_context) {
    OpenStruct.new({
      :enrollment_event_cv => enrollment_event_cv,
      :processing_errors => HandleEnrollmentEvent::ProcessingErrors.new,
      :raw_event_xml => raw_event_xml
    })
  }

  subject { HandleEnrollmentEvent::ExtractPolicyDetails.call(interaction_context) }

  describe "with no policy element" do
    let(:interaction_context) {
      OpenStruct.new({
        :enrollment_event_cv => nil,
        :processing_errors => HandleEnrollmentEvent::ProcessingErrors.new,
        :raw_event_xml => raw_event_xml
      })
    }

    it "should fail" do
      expect(subject.success?).to be_falsey
    end

    it "should log an error about the policy cv" do
      expect(subject.processing_errors.errors.get(:policy_cv)).to eq ["No policy found in source xml:\n\n#{raw_event_xml}"]
    end

  end

  describe "given a policy element" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :premium_total_amount => pre_amt_tot, :total_responsible_amount => tot_res_amt, :shop_market => shop_enrollment_element) }
    let(:policy_id) { "urn:openhbx:hbx:dc0:resources:v1:policy:hbx_id##{enrollment_group_id}" }

    it "extracts the transaction id" do
      expect(subject.policy_details.transaction_id).to eq transaction_id
    end

    it "extracts the enrollment group id" do
      expect(subject.policy_details.enrollment_group_id).to eq enrollment_group_id
    end

    it "extracts the pre_amt_tot" do
      expect(subject.policy_details.pre_amt_tot).to eq pre_amt_tot
    end

    it "extracts the market" do
      expect(subject.policy_details.market).to eq "shop"
    end

    it "extracts the tot_res_amt" do
      expect(subject.policy_details.tot_res_amt).to eq tot_res_amt
    end

    it "extracts the policy_cv" do
      expect(subject.policy_cv).to eq policy_cv
    end
  end

  describe "given a policy element with shop information" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :premium_total_amount => pre_amt_tot, :total_responsible_amount => tot_res_amt, :shop_market => shop_enrollment_element) }
    let(:policy_id) { "urn:openhbx:hbx:dc0:resources:v1:policy:hbx_id##{enrollment_group_id}" }

    it "extracts the tot_emp_res_amt" do
      expect(subject.policy_details.tot_emp_res_amt).to eq tot_emp_res_amt
    end
  end

  describe "given a policy element with ivl information" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :premium_total_amount => pre_amt_tot, :total_responsible_amount => tot_res_amt, :individual_market => individual_enrollment_element, shop_market: nil) }
    let(:policy_id) { "urn:openhbx:hbx:dc0:resources:v1:policy:hbx_id##{enrollment_group_id}" }

    it "extracts ivl market" do
      expect(subject.policy_details.market).to eq "individual"
    end
  end
end
