require "rails_helper"

class TestClassForTermninationDateHelper
  include ::EnrollmentAction::TerminationDateHelper

  attr_reader :action, :termination

  def initialize(term, act)
    @action = act
    @termination = term
  end
end

describe EnrollmentAction::TerminationDateHelper, "given:
- a termination on an already active enrollment
- new purchase" do

  let(:action) { instance_double(ExternalEvents::EnrollmentEventNotification, :subscriber_start => new_action_start_date) }
  let(:termination) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_policy => existing_policy, :subscriber_end => termination_event_end_date) }
  let(:existing_policy) { instance_double(Policy, :policy_start => policy_start) }

  subject { TestClassForTermninationDateHelper.new(termination, action) }

  describe "when the termination is a cancel, and the existing policy doesn't have an earlier start" do
    let(:policy_start) { Date.new(2017, 1, 1) }
    let(:termination_event_end_date) { policy_start }
    let(:new_action_start_date) { policy_start }

    it "returns the end date from the termination event" do
      expect(subject.select_termination_date).to eq termination_event_end_date
    end
  end

  describe "when the termination is a cancel, and the existing policy has an earlier start" do
    let(:policy_start) { Date.new(2017, 1, 1) }
    let(:termination_event_end_date) { Date.new(2017, 2, 1) }
    let(:new_action_start_date) { Date.new(2017, 2, 1) }
    let(:one_day_before_start) { new_action_start_date - 1.day  }

    it "returns the end date as the start of the new purchase minus one day" do
      expect(subject.select_termination_date).to eq one_day_before_start
    end
  end
end
