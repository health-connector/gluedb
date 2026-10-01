require 'rails_helper'

describe TradingPartnerTransforms::EndDateApplier, :dbclean => :after_each do

  let(:user_email) { "ediops@example.com" }
  let(:policy) { FactoryGirl.create(:policy) }

  def build_request(overrides = {})
    TradingPartnerTransformRequest.new({ :eg_ids => policy.eg_id }.merge(overrides))
  end

  describe "#apply! with change / terminate" do
    let(:end_date) { policy.policy_start + 2.months }
    let(:transform_request) { build_request(:end_date_action => "change", :change_mode => "terminate", :end_date => end_date.strftime('%m/%d/%Y')) }

    it "sets the enrollee end date and status, and terminates the policy" do
      described_class.new(transform_request, user_email).apply!
      policy.reload
      expect(policy.enrollees.map(&:coverage_end).uniq).to eq [end_date]
      expect(policy.enrollees.map(&:emp_stat).uniq).to eq ["terminated"]
      expect(policy.enrollees.map(&:coverage_status).uniq).to eq ["inactive"]
      expect(policy.aasm_state).to eq "terminated"
    end

    describe "when the entered date happens to equal the policy start date" do
      let(:end_date) { policy.policy_start }

      it "cancels the policy instead of terminating it" do
        described_class.new(transform_request, user_email).apply!
        expect(policy.reload.aasm_state).to eq "canceled"
      end
    end
  end

  describe "#apply! with change / cancel" do
    let(:transform_request) { build_request(:end_date_action => "change", :change_mode => "cancel") }

    it "sets every enrollee end date to the policy's own start date and cancels it" do
      described_class.new(transform_request, user_email).apply!
      policy.reload
      expect(policy.enrollees.map(&:coverage_end).uniq).to eq [policy.policy_start]
      expect(policy.aasm_state).to eq "canceled"
    end
  end

  describe "#apply! with remove" do
    let(:policy) { FactoryGirl.create(:terminated_policy) }
    let(:transform_request) { build_request(:end_date_action => "remove", :aasm_state => "resubmitted", :benefit_status => "cobra") }

    it "clears the end date, reactivates coverage, and restores the requested state" do
      described_class.new(transform_request, user_email).apply!
      policy.reload
      expect(policy.enrollees.map(&:coverage_end).uniq).to eq [nil]
      expect(policy.enrollees.map(&:emp_stat).uniq).to eq ["active"]
      expect(policy.enrollees.map(&:coverage_status).uniq).to eq ["active"]
      expect(policy.enrollees.map(&:ben_stat).uniq).to eq ["cobra"]
      expect(policy.aasm_state).to eq "resubmitted"
    end
  end

  describe "#apply! with remove_cobra" do
    let(:transform_request) { build_request(:end_date_action => "remove_cobra") }

    before { policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 1, 1)) }

    it "unsets only the cobra eligibility date" do
      original_state = policy.aasm_state
      original_end_dates = policy.enrollees.map(&:coverage_end)
      described_class.new(transform_request, user_email).apply!
      policy.reload
      expect(policy.cobra_eligibility_date).to be_nil
      expect(policy.aasm_state).to eq original_state
      expect(policy.enrollees.map(&:coverage_end)).to eq original_end_dates
    end
  end

  describe "#apply! with none selected" do
    let(:transform_request) { build_request(:end_date_action => "none") }

    it "changes nothing at all" do
      original_state = policy.aasm_state
      original_end_dates = policy.enrollees.map(&:coverage_end)
      described_class.new(transform_request, user_email).apply!
      policy.reload
      expect(policy.aasm_state).to eq original_state
      expect(policy.enrollees.map(&:coverage_end)).to eq original_end_dates
    end
  end

  describe "#apply! across multiple policies" do
    let(:other_policy) { FactoryGirl.create(:policy) }
    let(:transform_request) { build_request(:eg_ids => "#{policy.eg_id},#{other_policy.eg_id}", :end_date_action => "remove_cobra") }

    before do
      policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 1, 1))
      other_policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 2, 2))
    end

    it "applies the action to every policy in the batch" do
      described_class.new(transform_request, user_email).apply!
      expect(policy.reload.cobra_eligibility_date).to be_nil
      expect(other_policy.reload.cobra_eligibility_date).to be_nil
    end
  end

  describe "policy history" do
    it "records the acting user and keeps the previous enrollee end dates in the version history" do
      original_end_dates = policy.enrollees.map(&:coverage_end)
      original_version = policy.version
      end_date = policy.policy_start + 2.months
      transform_request = build_request(:end_date_action => "change", :change_mode => "terminate", :end_date => end_date.strftime('%m/%d/%Y'))
      described_class.new(transform_request, user_email).apply!
      policy.reload
      expect(policy.updated_by).to eq user_email
      expect(policy.version).to eq original_version + 1
      expect(policy.versions.last.enrollees.map(&:coverage_end)).to eq original_end_dates
    end

    it "records the acting user for a remove" do
      transform_request = build_request(:end_date_action => "remove", :aasm_state => "submitted", :benefit_status => "active")
      described_class.new(transform_request, user_email).apply!
      expect(policy.reload.updated_by).to eq user_email
    end

    it "saves a remove_cobra change as a new policy version by the acting user" do
      policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 1, 1))
      original_version = policy.reload.version
      transform_request = build_request(:end_date_action => "remove_cobra")
      described_class.new(transform_request, user_email).apply!
      policy.reload
      expect(policy.updated_by).to eq user_email
      expect(policy.version).to eq original_version + 1
      expect(policy.versions.last.cobra_eligibility_date).to eq Date.new(2026, 1, 1)
    end
  end

  describe "when one policy in the batch fails" do
    let(:other_policy) { FactoryGirl.create(:policy) }
    let(:transform_request) { build_request(:eg_ids => "#{policy.eg_id},#{other_policy.eg_id}", :end_date_action => "remove_cobra") }
    let(:applier) { described_class.new(transform_request, user_email) }

    before do
      policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 1, 1))
      other_policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 2, 2))
      failing_policy = transform_request.policies.detect { |p| p.eg_id == other_policy.eg_id }
      allow(failing_policy).to receive(:save!).and_raise(StandardError, "save failed")
      applier.apply!
    end

    it "still applies the other policies" do
      expect(policy.reload.cobra_eligibility_date).to be_nil
      expect(applier.applied_eg_ids).to eq [policy.eg_id]
    end

    it "leaves the failed policy unchanged and reports it" do
      expect(other_policy.reload.cobra_eligibility_date).to eq Date.new(2026, 2, 2)
      expect(applier.failures).to eq [[other_policy.eg_id, "save failed"]]
    end
  end

  describe "audit logging" do
    it "logs the acting user, ticket, action, and eg_id for a change" do
      transform_request = build_request(:ticket_number => "CCAOM-297", :end_date_action => "change", :change_mode => "terminate", :end_date => (policy.policy_start + 1.month).strftime('%m/%d/%Y'))
      expect(Rails.logger).to receive(:info).with(a_string_matching(/user=#{user_email}.*ticket=CCAOM-297.*action=change.*eg_id=#{policy.eg_id}/))
      described_class.new(transform_request, user_email).apply!
    end

    it "logs ticket=none when no ticket number was entered" do
      transform_request = build_request(:end_date_action => "remove_cobra")
      expect(Rails.logger).to receive(:info).with(a_string_matching(/ticket=none/))
      described_class.new(transform_request, user_email).apply!
    end

    it "logs the restore state and benefit status for a remove" do
      transform_request = build_request(:end_date_action => "remove", :aasm_state => "effectuated", :benefit_status => "active")
      expect(Rails.logger).to receive(:info).with(a_string_matching(/aasm_state=effectuated benefit_status=active/))
      described_class.new(transform_request, user_email).apply!
    end
  end
end
