require 'rails_helper'

describe TradingPartnerTransformRequest, :dbclean => :after_each do

  let(:policy) { FactoryGirl.create(:policy) }
  let(:other_policy) { FactoryGirl.create(:policy) }

  let(:valid_generate_params) do
    { :eg_ids => policy.eg_id, :reason_code => "terminate_enrollment" }
  end

  let(:valid_apply_change_terminate_params) do
    {
      :eg_ids => policy.eg_id,
      :end_date_action => "change",
      :change_mode => "terminate",
      :end_date => (policy.policy_start + 2.months).strftime('%m/%d/%Y')
    }
  end

  describe "#initialize defaults" do
    it "strips whitespace from the ticket number" do
      subject = described_class.new(:ticket_number => "  CCAOM-297  ")
      expect(subject.ticket_number).to eq "CCAOM-297"
    end

    it "defaults ticket_number to an empty string when not given" do
      subject = described_class.new
      expect(subject.ticket_number).to eq ""
    end

    it "defaults end_date_action to none" do
      expect(described_class.new.end_date_action).to eq "none"
      expect(described_class.new(:end_date_action => "").end_date_action).to eq "none"
    end

    it "defaults change_mode to terminate" do
      expect(described_class.new.change_mode).to eq "terminate"
      expect(described_class.new(:change_mode => "").change_mode).to eq "terminate"
    end

    it "defaults aasm_state to submitted" do
      expect(described_class.new.aasm_state).to eq "submitted"
    end

    it "defaults benefit_status to active" do
      expect(described_class.new.benefit_status).to eq "active"
    end

    it "accepts a nil props hash without raising" do
      expect { described_class.new(nil) }.not_to raise_error
    end
  end

  describe "#eg_id_list" do
    it "splits on commas, strips whitespace, drops blanks, and dedupes" do
      subject = described_class.new(:eg_ids => " 100, 100 ,, 200")
      expect(subject.eg_id_list).to eq ["100", "200"]
    end

    it "is empty for a blank eg_ids value" do
      expect(described_class.new(:eg_ids => nil).eg_id_list).to eq []
      expect(described_class.new(:eg_ids => "").eg_id_list).to eq []
    end
  end

  describe "#policies and #missing_eg_ids" do
    it "finds only the policies that actually exist" do
      subject = described_class.new(:eg_ids => "#{policy.eg_id},does_not_exist")
      expect(subject.policies).to eq [policy]
      expect(subject.missing_eg_ids).to eq ["does_not_exist"]
    end

    it "returns policies in no particular guaranteed order beyond matching each eg_id once" do
      subject = described_class.new(:eg_ids => "#{policy.eg_id},#{other_policy.eg_id}")
      expect(subject.policies).to match_array([policy, other_policy])
    end
  end

  describe "#transform_reason_code" do
    it "maps cancel to terminate_enrollment for the transform pipeline" do
      subject = described_class.new(:reason_code => "cancel")
      expect(subject.transform_reason_code).to eq "terminate_enrollment"
    end

    it "passes every other reason code through unchanged" do
      subject = described_class.new(:reason_code => "initial")
      expect(subject.transform_reason_code).to eq "initial"
    end
  end

  describe "zip naming" do
    describe "with a ticket number" do
      subject { described_class.new(:ticket_number => "CCAOM 297/a", :reason_code => "initial") }

      it "sanitizes unsafe characters and prefixes the zip name" do
        expect(subject.zip_file_name).to eq "CCAOM_297_a_initial_transform_xmls.zip"
      end

      it "uses the same prefix for the source only zip" do
        expect(subject.source_zip_file_name).to eq "CCAOM_297_a_initial_source_xml.zip"
      end
    end

    describe "with no ticket number" do
      subject { described_class.new(:reason_code => "initial") }

      it "omits the prefix entirely" do
        expect(subject.zip_file_name).to eq "initial_transform_xmls.zip"
        expect(subject.source_zip_file_name).to eq "initial_source_xml.zip"
        expect(subject.zip_prefix).to eq ""
      end
    end

    it "keeps the cancel reason in the file name even though the pipeline sees terminate_enrollment" do
      subject = described_class.new(:reason_code => "cancel")
      expect(subject.zip_file_name).to eq "cancel_transform_xmls.zip"
    end
  end

  describe "#end_date_action_selected?" do
    it "is false for none" do
      expect(described_class.new(:end_date_action => "none").end_date_action_selected?).to be_falsey
    end

    it "is true for anything else" do
      expect(described_class.new(:end_date_action => "remove").end_date_action_selected?).to be_truthy
      expect(described_class.new(:end_date_action => "change").end_date_action_selected?).to be_truthy
      expect(described_class.new(:end_date_action => "remove_cobra").end_date_action_selected?).to be_truthy
    end
  end

  describe "#parsed_end_date" do
    it "parses a valid MM/DD/YYYY date" do
      subject = described_class.new(:end_date => "03/31/2026")
      expect(subject.parsed_end_date).to eq Date.new(2026, 3, 31)
    end

    it "is nil for a blank date" do
      expect(described_class.new(:end_date => nil).parsed_end_date).to be_nil
      expect(described_class.new(:end_date => "").parsed_end_date).to be_nil
    end

    it "is nil for the ISO format, only MM/DD/YYYY is accepted" do
      expect(described_class.new(:end_date => "2026-03-31").parsed_end_date).to be_nil
    end

    it "is nil for garbage input" do
      expect(described_class.new(:end_date => "not a date").parsed_end_date).to be_nil
    end

    it "is nil for an out of range calendar date" do
      expect(described_class.new(:end_date => "13/45/2026").parsed_end_date).to be_nil
    end

    it "does not misread 3/1/2026 as January" do
      subject = described_class.new(:end_date => "03/01/2026")
      expect(subject.parsed_end_date).to eq Date.new(2026, 3, 1)
    end
  end

  describe "#effective_end_date_for" do
    describe "terminate mode" do
      subject { described_class.new(:end_date => "06/15/2026", :change_mode => "terminate") }

      it "uses the typed in end date regardless of the policy" do
        expect(subject.effective_end_date_for(policy)).to eq Date.new(2026, 6, 15)
      end
    end

    describe "cancel mode" do
      subject { described_class.new(:change_mode => "cancel") }

      it "uses the policy's own start date" do
        expect(subject.effective_end_date_for(policy)).to eq policy.policy_start
      end

      it "is nil when the policy has no self relationship enrollee" do
        policy.enrollees.each { |en| en.update_attributes!(:rel_code => "child") }
        policy.reload
        expect(subject.effective_end_date_for(policy)).to be_nil
      end
    end
  end

  describe "#policy_previews" do
    describe "for none" do
      subject { described_class.new(:eg_ids => policy.eg_id, :end_date_action => "none") }

      it "reports no planned change" do
        preview = subject.policy_previews.first
        expect(preview[:planned_changes]).to eq "none"
        expect(preview[:planned_aasm_state]).to be_nil
        expect(preview[:planned_benefit_status]).to be_nil
      end
    end

    describe "for remove" do
      subject do
        described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove", :aasm_state => "resubmitted", :benefit_status => "cobra")
      end

      it "reports the chosen restore state and benefit status" do
        preview = subject.policy_previews.first
        expect(preview[:planned_aasm_state]).to eq "resubmitted"
        expect(preview[:planned_benefit_status]).to eq "cobra"
        expect(preview[:planned_changes]).to include("resubmitted")
        expect(preview[:planned_changes]).to include("cobra")
      end

      it "shows the current state and current end dates for the confirm table" do
        preview = subject.policy_previews.first
        expect(preview[:current_aasm_state]).to eq policy.aasm_state
        expect(preview[:current_end_dates]).to eq policy.enrollees.map(&:coverage_end).uniq
      end
    end

    describe "for change / terminate" do
      let(:end_date) { policy.policy_start + 2.months }
      subject do
        described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => end_date.strftime('%m/%d/%Y'))
      end

      it "reports the typed in date and a terminated outcome" do
        preview = subject.policy_previews.first
        expect(preview[:planned_end_date]).to eq end_date
        expect(preview[:planned_aasm_state]).to eq "terminated"
        expect(preview[:planned_changes]).to include(end_date.strftime('%m/%d/%Y'))
        expect(preview[:planned_changes]).to include("terminate")
      end
    end

    describe "for change / cancel" do
      subject { described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "cancel") }

      it "reports the policy start date and a canceled outcome" do
        preview = subject.policy_previews.first
        expect(preview[:planned_end_date]).to eq policy.policy_start
        expect(preview[:planned_aasm_state]).to eq "canceled"
        expect(preview[:planned_changes]).to include("cancel")
      end

      it "explains itself instead of crashing when the policy has no self relationship enrollee" do
        policy.enrollees.each { |en| en.update_attributes!(:rel_code => "child") }
        policy.reload
        preview = subject.policy_previews.first
        expect(preview[:planned_changes]).to include("cannot determine a cancel date")
      end
    end

    describe "for remove_cobra" do
      subject { described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove_cobra") }

      it "reports no discrete state or benefit change" do
        preview = subject.policy_previews.first
        expect(preview[:planned_aasm_state]).to be_nil
        expect(preview[:planned_benefit_status]).to be_nil
        expect(preview[:planned_changes]).to include("cobra eligibility date removed")
      end

      it "shows the current cobra date when one is set" do
        policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 1, 1))
        preview = subject.policy_previews.first
        expect(preview[:planned_changes]).to include("01/01/2026")
      end

      it "says not set when there is no current cobra date" do
        preview = subject.policy_previews.first
        expect(preview[:planned_changes]).to include("not set")
      end
    end
  end

  describe "self.reason_code_options" do
    it "offers cancel alongside the pipeline reason codes" do
      values = described_class.reason_code_options.map(&:last)
      expect(values).to include("cancel", "initial", "terminate_enrollment")
    end
  end

  describe "validations under the :generate context" do
    it "requires eg_ids" do
      subject = described_class.new(valid_generate_params.merge(:eg_ids => ""))
      expect(subject.valid?(:generate)).to be_falsey
      expect(subject.errors[:eg_ids]).not_to be_empty
    end

    it "requires every eg_id to resolve to a real policy" do
      subject = described_class.new(valid_generate_params.merge(:eg_ids => "#{policy.eg_id},bogus"))
      expect(subject.valid?(:generate)).to be_falsey
      expect(subject.errors[:eg_ids].first).to include("bogus")
    end

    it "rejects a batch over the policy count limit" do
      too_many = (1..(described_class::MAX_POLICIES + 1)).map { |n| "eg#{n}" }.join(",")
      subject = described_class.new(valid_generate_params.merge(:eg_ids => too_many))
      expect(subject.valid?(:generate)).to be_falsey
      expect(subject.errors[:eg_ids].any? { |m| m.include?("maximum") }).to be_truthy
    end

    it "requires a recognized reason code" do
      subject = described_class.new(valid_generate_params.merge(:reason_code => "bogus_reason"))
      expect(subject.valid?(:generate)).to be_falsey
      expect(subject.errors[:reason_code]).not_to be_empty
    end

    it "accepts cancel as a reason code" do
      subject = described_class.new(valid_generate_params.merge(:reason_code => "cancel"))
      expect(subject.valid?(:generate)).to be_truthy
    end

    it "is valid with correct eg_ids and reason_code" do
      subject = described_class.new(valid_generate_params)
      expect(subject.valid?(:generate)).to be_truthy
    end

    it "does not validate end_date_action, so garbage there does not block generate" do
      subject = described_class.new(valid_generate_params.merge(:end_date_action => "totally_bogus"))
      expect(subject.valid?(:generate)).to be_truthy
    end
  end

  describe "validations under the :apply_changes context" do
    it "does not require a reason code" do
      subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove_cobra", :reason_code => "bogus_reason")
      expect(subject.valid?(:apply_changes)).to be_truthy
    end

    it "still requires eg_ids" do
      subject = described_class.new(:eg_ids => "", :end_date_action => "remove_cobra")
      expect(subject.valid?(:apply_changes)).to be_falsey
    end

    it "requires an action to be selected, none is not enough" do
      subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "none")
      expect(subject.valid?(:apply_changes)).to be_falsey
      expect(subject.errors[:end_date_action]).not_to be_empty
    end

    it "rejects an end_date_action outside the known list" do
      subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "bogus_action")
      expect(subject.valid?(:apply_changes)).to be_falsey
      expect(subject.errors[:end_date_action]).not_to be_empty
    end

    describe "remove" do
      it "is valid with the default restore state and benefit status" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove")
        expect(subject.valid?(:apply_changes)).to be_truthy
      end

      it "accepts resubmitted as a restore state" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove", :aasm_state => "resubmitted")
        expect(subject.valid?(:apply_changes)).to be_truthy
      end

      it "rejects an unknown restore state" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove", :aasm_state => "bogus_state")
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:aasm_state]).not_to be_empty
      end

      it "rejects an unknown benefit status" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove", :benefit_status => "bogus_status")
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:benefit_status]).not_to be_empty
      end
    end

    describe "remove_cobra" do
      it "is valid with no extra fields" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "remove_cobra")
        expect(subject.valid?(:apply_changes)).to be_truthy
      end
    end

    describe "change with an unknown change_mode" do
      it "is invalid" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "bogus_mode")
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:change_mode]).not_to be_empty
      end
    end

    describe "change / terminate" do
      it "requires an end date" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => "")
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:end_date]).not_to be_empty
      end

      it "rejects an end date that fails to parse" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => "2026-03-31")
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:end_date]).not_to be_empty
      end

      it "rejects an end date equal to the policy start date, pointing at Cancel instead" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => policy.policy_start.strftime('%m/%d/%Y'))
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:end_date].first).to include("Use Cancel")
      end

      it "rejects an end date before the policy start date" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => (policy.policy_start - 1.day).strftime('%m/%d/%Y'))
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:end_date].first).to include("after the policy start date")
      end

      it "accepts an end date a few months after the policy start date" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => (policy.policy_start + 5.months).strftime('%m/%d/%Y'))
        expect(subject.valid?(:apply_changes)).to be_truthy
      end

      it "accepts the last day of the first year, one day before the one year anniversary" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => (policy.policy_start + 1.year - 1.day).strftime('%m/%d/%Y'))
        expect(subject.valid?(:apply_changes)).to be_truthy
      end

      it "rejects an end date on the one year anniversary" do
        last_end_date = policy.policy_start + 1.year - 1.day
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => (policy.policy_start + 1.year).strftime('%m/%d/%Y'))
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:end_date].first).to include("on or before #{last_end_date.strftime('%m/%d/%Y')}")
      end

      it "explains itself instead of crashing when the policy has no self relationship enrollee" do
        policy.enrollees.each { |en| en.update_attributes!(:rel_code => "child") }
        policy.reload
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => "06/15/2026")
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:eg_ids].first).to include("no self relationship coverage start date")
      end

      describe "with multiple policies" do
        it "is valid, one typed in date always applies to every policy" do
          subject = described_class.new(
            :eg_ids => "#{policy.eg_id},#{other_policy.eg_id}",
            :end_date_action => "change",
            :change_mode => "terminate",
            :end_date => (policy.policy_start + 2.months).strftime('%m/%d/%Y')
          )
          expect(subject.valid?(:apply_changes)).to be_truthy
        end
      end
    end

    describe "change / cancel" do
      it "is valid with no end date entered at all" do
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "cancel")
        expect(subject.valid?(:apply_changes)).to be_truthy
      end

      it "explains itself instead of crashing when the policy has no self relationship enrollee" do
        policy.enrollees.each { |en| en.update_attributes!(:rel_code => "child") }
        policy.reload
        subject = described_class.new(:eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "cancel")
        expect(subject.valid?(:apply_changes)).to be_falsey
        expect(subject.errors[:eg_ids].first).to include("no self relationship coverage start date")
      end

      describe "with multiple policies that share the same start date" do
        it "is valid" do
          other_policy.enrollees.each { |en| en.update_attributes!(:coverage_start => policy.policy_start) }
          other_policy.reload
          subject = described_class.new(:eg_ids => "#{policy.eg_id},#{other_policy.eg_id}", :end_date_action => "change", :change_mode => "cancel")
          expect(subject.valid?(:apply_changes)).to be_truthy
        end
      end

      describe "with multiple policies that have different start dates" do
        it "is invalid, naming the mismatched eg_ids and dates" do
          other_policy.subscriber.update_attributes!(:coverage_start => policy.policy_start + 1.month)
          other_policy.reload
          subject = described_class.new(:eg_ids => "#{policy.eg_id},#{other_policy.eg_id}", :end_date_action => "change", :change_mode => "cancel")
          expect(subject.valid?(:apply_changes)).to be_falsey
          message = subject.errors[:eg_ids].last
          expect(message).to include(policy.eg_id)
          expect(message).to include(other_policy.eg_id)
        end
      end
    end
  end
end
