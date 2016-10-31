require "rails_helper"

describe HandlePolicyNotification::VerifyRequiredDetailsPresent do
  let(:enrollment_group_id) { "2938749827349723974" }
  let(:pre_amt_tot) { 290.13 }
  let(:tot_res_amt) { 123.13 }
  let(:tot_emp_res_amt) { 234.30 }
  let(:hios_id) { "88889999888833" }

  let(:member_id) { "2938749827349723974" }
  let(:is_subscriber) { true }
  let(:member_premium) { 123.13 }
  let(:coverage_start) { "20160101" }
  let(:coverage_end) { "20161231" }
  let(:eligibility_start) { "20160103" }

  let(:plan_record){ FactoryGirl.create(:plan, year: 2017, market_type: "shop") }
  let(:broker_record){ instance_double("Broker") }
  let(:employer_record){ instance_double("Employer") }
  let(:member_record){ instance_double("Member") }

  let(:enrollee) {
    ::HandlePolicyNotification::MemberDetails.new({
       :premium_amount => member_premium,
       :member_id => member_id,
       :is_subscriber => true,
       :begin_date => coverage_start,
       :end_date => coverage_end,
       :eligibility_begin_date => eligibility_start
    })
  }

  let(:broker_link) {
    HandlePolicyNotification::BrokerDetails.new({
       :npn => "3838383838"
    })
  }

  let(:policy_cv) {
    instance_double(
      Openhbx::Cv2::Policy,
      :id => policy_id,
      :policy_enrollment => policy_enrollment,
      enrollees: [enrollee],
      broker_link: broker_link
    )
  }

  let(:plan_link){
    ::HandlePolicyNotification::PlanDetails.new({
      :hios_id => hios_id,
      :active_year => 2017
    })
  }

  let(:policy_enrollment) {
    instance_double(
      Openhbx::Cv2::PolicyEnrollment,
      plan: plan_link,
      :premium_total_amount => pre_amt_tot,
      :total_responsible_amount => tot_res_amt,
      :shop_market => shop_enrollment_element
    )
  }

  let(:shop_enrollment_element) {
    instance_double(
      Openhbx::Cv2::PolicyEnrollmentShopMarket,
      :total_employer_responsible_amount => tot_emp_res_amt,
      employer_link: employer_link
    )
  }

  let(:employer_link){
    ::HandlePolicyNotification::EmployerDetails.new({
      :fein => "484848484"
    })
  }

  let(:interaction_context) {
    OpenStruct.new({
      :policy_cv => policy_cv,
      :processing_errors => HandlePolicyNotification::ProcessingErrors.new
    })
  }

  subject { HandlePolicyNotification::VerifyRequiredDetailsPresent.call(interaction_context) }


  describe "given a policy element" do
    let(:policy_id) { "urn:openhbx:hbx:dc0:resources:v1:policy:hbx_id##{enrollment_group_id}" }

    before :each do
      allow(plan_link).to receive(:found_plan).and_return(plan_record)
      allow(broker_link).to receive(:found_broker).and_return(broker_record)
      allow(employer_link).to receive(:found_employer).and_return(employer_record)
      allow(enrollee).to receive(:found_member).and_return(member_record)
    end

    it "extracts the enrollment group id" do
      expect(subject.policy_cv.id.split("#").last).to eq enrollment_group_id
    end

    it "extracts the pre_amt_tot" do
      expect(subject.policy_cv.policy_enrollment.premium_total_amount).to eq pre_amt_tot
    end

    it "should return no error" do
      expect(subject.processing_errors.has_errors?).to eq false
    end

  end

  describe "given a policy element" do
    let(:policy_id) { "urn:openhbx:hbx:dc0:resources:v1:policy:hbx_id##{enrollment_group_id}" }

    it "should return error" do
      expect(subject.processing_errors.has_errors?).to eq true
      expect(subject.processing_errors.errors[:employer_details]).to eq ["No employer found with fein 484848484"]
      expect(subject.processing_errors.errors[:plan_details]).to eq ["No plan found with HIOS ID 88889999888833 and active year 2017"]
      expect(subject.processing_errors.errors[:member_details]).to eq ["No member found with hbx id 2938749827349723974"]
      expect(subject.processing_errors.errors[:broker_details]).to eq ["No broker found with npn 3838383838"]
    end

  end

end