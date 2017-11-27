require "rails_helper"

describe ExternalEvents::ExternalPolicy, "given:
- a cv policy object
- a plan
" do

  let(:plan_cv) { instance_double(Openhbx::Cv2::PlanLink, :alias_ids => alias_ids) }
  let!(:policy_enrollment) { instance_double(Openhbx::Cv2::PolicyEnrollment, :rating_area => rating_area, :plan => plan_cv, :shop_market => shop_market) }
  let(:policy_cv) { instance_double(Openhbx::Cv2::Policy, :policy_enrollment => policy_enrollment, :enrollees =>[enrollees1, enrollees2]) }
  let!(:enrollees1) { double("Enrollee", subscriber?: "rspec" )}
  let!(:enrollees2) { double("Enrollee", subscriber?: "rspec2") }
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

  describe ".Persist" do
  
    let!(:responsible_party) { ResponsibleParty.new(entity_identifier: "responsible party") }
    let!(:person) { FactoryGirl.create(:person,responsible_parties:[responsible_party])}

    context "when policy and responsible party exists" do

      let!(:policy) {FactoryGirl.create(:policy,responsible_party_id:responsible_party.id) }
      before :each do
        allow(subject).to receive(:policy_exists?).and_return(true)
        allow(subject).to receive(:existing_policy).and_return(policy)
        allow(subject).to receive(:responsible_party_exists?).and_return(true)
        allow(policy).to receive(:has_responsible_person?).and_return(true)
        allow(subject).to receive(:existing_responsible_party).and_return(responsible_party)
      end

      it "should not update responsible party of policy" do
        subject.persist
        expect(policy.responsible_party_id).to eq responsible_party.id
      end

       it "should not create responsible party" do
        subject.persist
        expect(person.responsible_parties.count).to eq 1
      end
    end

    context "when policy has no responsible party " do

      let!(:policy) {FactoryGirl.create(:policy) }

      before :each do
        allow(subject).to receive(:policy_exists?).and_return(true)
        allow(subject).to receive(:existing_policy).and_return(policy)
      end

      context "with responsible party exists" do
        before :each do
          allow(subject).to receive(:responsible_party_exists?).and_return(true)
          allow(subject).to receive(:existing_responsible_party).and_return(responsible_party)
        end

        it "should update with responsible party of policy" do
          expect(policy.responsible_party_id).to eq nil
          subject.persist
          expect(policy.responsible_party_id).to eq responsible_party.id
        end
      end

      context "with no responsible party" do

        let!(:person) { FactoryGirl.create(:person)}

        before :each do
          allow(subject).to receive(:responsible_party_exists?).and_return(false)
          allow(subject).to receive(:responsible_person_exists?).and_return(true)
          allow(subject).to receive(:responsible_person).and_return(person)
        end

        it "should create responsible party" do
          expect(person.responsible_parties).to eq []
          subject.persist
          expect(person.responsible_parties.exists?).to eq true
        end

        it "should update policy with responsible party" do
          subject.persist
          expect(policy.responsible_party_id).to eq person.responsible_parties.first.id
        end
      end
    end

    context "when policy not exists and responsible party exists", dbclean: :after_each do

      let!(:plan) {FactoryGirl.create(:plan, carrier_id:'01') }
      let(:applied_aptc) { {:applied_aptc =>'0.0'} }

      before :each do
        allow(subject).to receive(:policy_exists?).and_return(false)
        allow(subject).to receive(:responsible_party_exists?).and_return(true)
        allow(subject).to receive(:existing_responsible_party).and_return(responsible_party)
        allow(subject).to receive(:extract_enrollment_group_id).with(policy_cv).and_return('rspec-eg-id')
        allow(subject).to receive(:extract_pre_amt_tot).and_return("0.0")
        allow(subject).to receive(:extract_tot_res_amt).and_return("0.0")
        allow(subject).to receive(:extract_other_financials).and_return(applied_aptc)
        allow(subject).to receive(:extract_rating_details).and_return({})
        allow(subject).to receive(:extract_subscriber).with(policy_cv).and_return("rspec-sub-node")
        allow(subject).to receive(:subscriber_id).and_return("rspec-id")
        allow(subject).to receive(:extract_enrollee_start).with("rspec-sub-node").and_return(Date.today)
        allow(subject).to receive(:extract_enrollee_premium).with("rspec-sub-node").and_return("100")
        subject.instance_variable_set(:@plan,plan)
      end

      it "should create policy and update responsible party for policy" do
        subject.persist
        expect(Policy.where(eg_id: "rspec-eg-id").exists?).to eq true
        expect(Policy.where(eg_id: "rspec-eg-id").first.enrollees.exists?).to eq true
        expect(Policy.where(eg_id: "rspec-eg-id").first.responsible_party_id).to eq responsible_party.id
      end
    end
  end
end
