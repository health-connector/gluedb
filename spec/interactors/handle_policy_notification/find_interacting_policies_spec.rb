require "rails_helper"

describe HandlePolicyNotification::FindInteractingPolicies do
  describe ".overlap_date_range" do
    subject { HandlePolicyNotification::FindInteractingPolicies.new.overlap_date_range(event_start,event_end,policy_start,policy_end,event_year,policy_year) }
    let(:start_date) { Date.today }
    let(:end_date) { start_date + 2.weeks }
    let(:policy_start) { start_date }
    let(:event_start) { start_date }
    let(:policy_end) { end_date }
    let(:event_end) { end_date }
    let(:event_year) { start_date.year }
    let(:policy_year) { start_date.year }

    context "no end dates" do
      let(:policy_end) { nil }
      let(:event_end) { nil }

      context "event years match" do
        it "overlaps" do
          expect(subject).to eq true
        end
      end

      context "event years don't match" do
        let(:policy_year) { policy_start.year + 1.year }

        it "does not overlap" do
          expect(subject).to eq false
        end
      end
    end

    context "same start dates" do
      it "overlaps" do
        expect(subject).to eq true
      end
    end

    context "event start is before policy start" do
      let(:event_start) { policy_start - 2.months }

      context "event has no end date" do
        let(:event_end) { nil }

        it "overlaps" do
          expect(subject).to eq true
        end
      end

      context "event ends before policy start" do
        let(:event_end) { policy_start - 1.week}

        it "does not overlap" do
          expect(subject).to eq false
        end
      end

      context "event ends after policy start" do
        let(:event_end) { policy_start + 1.week}

        it "overlaps" do
          expect(subject).to eq true
        end
      end
    end

    context "policy start is before event start" do
      let(:policy_start) { event_start - 2.months }

      context "policy has no end date" do
        let(:policy_end) { nil }

        it "overlaps" do
          expect(subject).to eq true
        end
      end

      context "policy ends before event start" do
        let(:policy_end) { event_start - 1.week}

        it "does not overlap" do
          expect(subject).to eq false
        end
      end

      context "policy ends after event start" do
        let(:policy_end) { event_start + 1.week}

        it "overlaps" do
          expect(subject).to eq true
        end
      end
    end

    context "event ends same day policy starts" do
      let(:event_end) { policy_start }

      it "overlaps" do
        expect(subject).to eq true
      end
    end

    context "policy ends same day event starts" do
      let(:policy_end) { event_start }

      it "overlaps" do
        expect(subject).to eq true
      end
    end
  end
end
