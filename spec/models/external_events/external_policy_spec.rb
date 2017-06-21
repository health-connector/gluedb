require "rails_helper"

describe ExternalEvents::ExternalPolicy, "given:
- a cv policy object
- a plan
" do

  let(:plan_cv) { instance_double(Openhbx::Cv2::PlanLink, :alias_ids => alias_ids) }
  let(:policy_enrollment) { instance_double(Openhbx::Cv2::PolicyEnrollment, :rating_area => rating_area, :plan => plan_cv, :shop_market => shop_market) }
  let(:policy_cv) { instance_double(Openhbx::Cv2::Policy, :policy_enrollment => policy_enrollment) }
  let(:plan) { instance_double(Plan) }
  let(:rating_area) { nil }
  let(:alias_ids) { nil }
  let(:shop_market) { nil }

  subject { ExternalEvents::ExternalPolicy.new(policy_cv, plan) }

  describe "and the policy cv has a rating area" do
    let(:rating_area) { "RATING AREA VALUE" }
    it "has the rating area" do
      expect(subject.extract_rating_details[:rating_area]).to eq rating_area
    end
  end

  describe "and the policy cv has carrier specific plan id" do
    let(:carrier_specific_plan_id) { "THE SPECIAL CARRIER PLAN ID" }
    let(:alias_ids) { [carrier_specific_plan_id] }

    it "has the carrier_specific_plan_id" do
      expect(subject.extract_rating_details[:carrier_specific_plan_id]).to eq carrier_specific_plan_id
    end
  end

  describe "and the policy is a shop policy" do
    let(:employer) { double }
    let(:shop_market) { instance_double(::Openhbx::Cv2::PolicyEnrollmentShopMarket, :total_employer_responsible_amount => total_employer_responsible_amount, :composite_rating_tier_name => composite_rating_tier_name) }
    let(:total_employer_responsible_amount) { "12345.23" }
    let(:composite_rating_tier_name) { "A COMPOSITE RATING TIER NAME" }

    before :each do
      allow(subject).to receive(:find_employer).with(policy_cv).and_return(employer)
    end

    describe "with a composite rating tier" do
      it "has the composite rating tier" do
        expect(subject.extract_other_financials[:composite_rating_tier]).to eq composite_rating_tier_name
      end

      it "has the employer responsible amount" do
        expect(subject.extract_other_financials[:tot_emp_res_amt]).to eq total_employer_responsible_amount.to_f
      end
    end
  end
end
