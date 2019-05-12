require "rails_helper"

describe Policy, "#calculated_premium_effective_date" do
  subject { policy.calculated_premium_effective_date }

  describe "for a SHOP policy" do
    let(:employer) { Employer.new }
    let(:plan_year) do
      instance_double(
        PlanYear,
        start_date: plan_year_start,
        end_date: plan_year_end
      )
    end

    let(:plan_year_start) { Date.new(2013, 4, 1) }
    # Let's play with a short plan year for our off-cycle renewals
    let(:plan_year_end) { Date.new(2014, 1, 31) }

    before :each do
      allow(employer).to receive(:plan_year_of).with(subscriber_start_date).and_return(plan_year)
    end

    let(:policy) do
      Policy.new(
        :enrollees => enrollees,
        :employer => employer
      )
    end

    describe "given a single active subscriber" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given a single cancelled subscriber" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          coverage_end: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given a single terminated subscriber" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber_end_date) { subscriber_start_date + 1.day }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          coverage_end: subscriber_end_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given a single terminated subscriber, terminated at the end of the year" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber_end_date) { plan_year_end }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          coverage_end: subscriber_end_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:enrollees) { [subscriber, canceled_dependent] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end
        )
      end

      let(:terminated_dependent_end) { subscriber_start_date + 25.days }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent] }

      it "uses one day after the dependent was terminated" do
        expect(subject).to eq(terminated_dependent_end + 1.day)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated
      - a dependent added during the coverage period of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end
        )
      end
      let(:intermediary_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end - 3.days
        )
      end

      let(:terminated_dependent_end) { subscriber_start_date + 25.days }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, intermediary_dependent] }

      it "uses one day after the last dependent termination" do
        expect(subject).to eq(terminated_dependent_end + 1.day)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated
      - a dependent added after the coverage period of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end
        )
      end
      let(:last_dependent) do
        Enrollee.new(
          coverage_start: last_dependent_start
        )
      end

      let(:last_dependent_start) { terminated_dependent_end + 7.days }
      let(:terminated_dependent_end) { subscriber_start_date + 25.days }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, last_dependent] }

      it "uses the last dependent addition date" do
        expect(subject).to eq(last_dependent_start)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated at the plan year
      - a dependent added after the coverage start of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: terminated_dependent_start,
          coverage_end: terminated_dependent_end
        )
      end
      let(:last_dependent) do
        Enrollee.new(
          coverage_start: last_dependent_start
        )
      end

      let(:last_dependent_start) { terminated_dependent_start + 7.days }
      let(:terminated_dependent_start) { subscriber_start_date + 7.days }
      let(:terminated_dependent_end) { plan_year_end }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, last_dependent] }

      it "uses the last dependent addition date" do
        expect(subject).to eq(last_dependent_start)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated one day before end of plan year
      - a dependent added after the coverage start of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: terminated_dependent_start,
          coverage_end: terminated_dependent_end
        )
      end
      let(:last_dependent) do
        Enrollee.new(
          coverage_start: last_dependent_start
        )
      end

      let(:last_dependent_start) { terminated_dependent_start + 7.days }
      let(:terminated_dependent_start) { subscriber_start_date + 7.days }
      let(:terminated_dependent_end) { plan_year_end - 1.day }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, last_dependent] }

      it "uses the last day of the plan year" do
        expect(subject).to eq(plan_year_end)
      end
    end
  end

  describe "for an IVL policy" do
    let(:policy) do
      Policy.new(
        :enrollees => enrollees
      )
    end

    let(:plan_year_end) { Date.new(subscriber_start_date.year, 12, 31) }

    describe "given a single active subscriber" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given a single cancelled subscriber" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          coverage_end: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given a single terminated subscriber" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber_end_date) { subscriber_start_date + 1.day }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          coverage_end: subscriber_end_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given a single terminated subscriber, terminated at the end of the year" do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber_end_date) { plan_year_end }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          coverage_end: subscriber_end_date,
          rel_code: "self"
        )
      end
      let(:enrollees) { [subscriber] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:enrollees) { [subscriber, canceled_dependent] }

      it "uses the subscriber start date" do
        expect(subject).to eq subscriber_start_date
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end
        )
      end

      let(:terminated_dependent_end) { subscriber_start_date + 25.days }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent] }

      it "uses one day after the dependent was terminated" do
        expect(subject).to eq(terminated_dependent_end + 1.day)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated
      - a dependent added during the coverage period of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end
        )
      end
      let(:intermediary_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end - 3.days
        )
      end

      let(:terminated_dependent_end) { subscriber_start_date + 25.days }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, intermediary_dependent] }

      it "uses one day after the last dependent termination" do
        expect(subject).to eq(terminated_dependent_end + 1.day)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated
      - a dependent added after the coverage period of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 7.days,
          coverage_end: terminated_dependent_end
        )
      end
      let(:last_dependent) do
        Enrollee.new(
          coverage_start: last_dependent_start
        )
      end

      let(:last_dependent_start) { terminated_dependent_end + 7.days }
      let(:terminated_dependent_end) { subscriber_start_date + 25.days }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, last_dependent] }

      it "uses the last dependent addition date" do
        expect(subject).to eq(last_dependent_start)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated at the plan year
      - a dependent added after the coverage start of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: terminated_dependent_start,
          coverage_end: terminated_dependent_end
        )
      end
      let(:last_dependent) do
        Enrollee.new(
          coverage_start: last_dependent_start
        )
      end

      let(:last_dependent_start) { terminated_dependent_start + 7.days }
      let(:terminated_dependent_start) { subscriber_start_date + 7.days }
      let(:terminated_dependent_end) { plan_year_end }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, last_dependent] }

      it "uses the last dependent addition date" do
        expect(subject).to eq(last_dependent_start)
      end
    end

    describe "given:
      - an active subscriber
      - a canceled dependent
      - an earlier dependent add than the cancel, that was terminated one day before end of plan year
      - a dependent added after the coverage start of the terminated dependent
    " do
      let(:subscriber_start_date) { Date.new(2013, 5, 5) }
      let(:subscriber) do
        Enrollee.new(
          coverage_start: subscriber_start_date,
          rel_code: "self"
        )
      end
      let(:canceled_dependent) do
        Enrollee.new(
          coverage_start: subscriber_start_date + 15.days,
          coverage_end: subscriber_start_date + 15.days
        )
      end
      let(:terminated_dependent) do
        Enrollee.new(
          coverage_start: terminated_dependent_start,
          coverage_end: terminated_dependent_end
        )
      end
      let(:last_dependent) do
        Enrollee.new(
          coverage_start: last_dependent_start
        )
      end

      let(:last_dependent_start) { terminated_dependent_start + 7.days }
      let(:terminated_dependent_start) { subscriber_start_date + 7.days }
      let(:terminated_dependent_end) { plan_year_end - 1.day }
      let(:enrollees) { [subscriber, canceled_dependent, terminated_dependent, last_dependent] }

      it "uses the last day of the plan year" do
        expect(subject).to eq(plan_year_end)
      end
    end
  end
end
