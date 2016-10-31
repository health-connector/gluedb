require "rails_helper"

describe HandlePolicyNotification::ExtractMemberDetails do
  let(:member_id) { "2938749827349723974" }
  let(:is_subscriber) { true }
  let(:member_premium) { 123.13 }
  let(:coverage_start) { "20160101" }
  let(:coverage_end) { "20161231" }
  let(:eligibility_start) { "20160103" }
  let(:enrollee_benefit) { instance_double(Openhbx::Cv2::EnrolleeBenefit, premium_amount: member_premium, begin_date: coverage_start, end_date: coverage_end, eligibility_begin_date: eligibility_start  ) }
  let(:enrollee_member) { instance_double(Openhbx::Cv2::EnrolleeMember, id: member_id  ) }
  let(:enrollees) { [instance_double(Openhbx::Cv2::Enrollee, is_subscriber: is_subscriber, benefit: enrollee_benefit, member: enrollee_member)] }
  let(:policy_cv) { instance_double(Openhbx::Cv2::Policy, enrollees: enrollees ) }

  let(:interaction_context) {
    OpenStruct.new({
      :policy_cv => policy_cv
    })
  }

  subject { HandlePolicyNotification::ExtractMemberDetails.call(interaction_context) }

  describe "given a policy member element" do

    it "extracts the member id" do
      expect(subject.member_detail_collection.first.member_id).to eq member_id
    end

    it "extracts the premium amount" do
      expect(subject.member_detail_collection.first.premium_amount).to eq member_premium
    end

    it "extracts the start date" do
      expect(subject.member_detail_collection.first.begin_date).to eq coverage_start.to_date
    end

    it "extracts the end date" do
      expect(subject.member_detail_collection.first.end_date).to eq coverage_end.to_date
    end

    it "extracts the eligibility start date" do
      expect(subject.member_detail_collection.first.eligibility_begin_date).to eq eligibility_start.to_date
    end

    it "extracts the is_subscriber" do
      expect(subject.member_detail_collection.first.is_subscriber).to eq is_subscriber
    end

  end

end
