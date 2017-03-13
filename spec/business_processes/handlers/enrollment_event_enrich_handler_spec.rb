require "rails_helper"

describe Handlers::EnrollmentEventEnrichHandler, "given:
- an enrollment termination event
- that event has no corresponding database record
- there is no other corresponding enrollment event notification
" do
  let(:next_step) { double }
  let(:event) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => true, :drop_if_bogus_term! => true) }

  subject { Handlers::EnrollmentEventEnrichHandler.new(next_step) }

  before :each do
    allow(event).to receive(:check_for_bogus_term_against).with([]).and_return(nil)
  end

  it "does not go on to the next step" do
    expect(next_step).not_to receive(:call)
    subject.call([event])
  end
end

describe Handlers::EnrollmentEventEnrichHandler, "given an event with a bogus plan year" do
  let(:next_step) { double }
  let(:event) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => true, :drop_if_bogus_term! => false) }

  subject { Handlers::EnrollmentEventEnrichHandler.new(next_step) }

  before :each do
    allow(event).to receive(:check_for_bogus_term_against).with([]).and_return(nil)
  end

  it "does not go on to the next step" do
    expect(next_step).not_to receive(:call)
    subject.call([event])
  end
end

describe Handlers::EnrollmentEventEnrichHandler, "given:
- two events
- one which occurs before the other
- the first event is a bogus renewal term" do
  let(:next_step) { double("FRANK") }
  let(:event_1) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => false, :drop_if_bogus_term! => false, :drop_if_bogus_renewal_term! => true) }
  let(:event_2) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => false, :drop_if_bogus_term! => false, :drop_if_bogus_renewal_term! => false) }
  let(:resolved_action_2) { instance_double(EnrollmentAction::Base) }

  subject { Handlers::EnrollmentEventEnrichHandler.new(next_step) }

  before :each do
    allow(event_1).to receive(:check_for_bogus_term_against).with([event_2]).and_return(nil)
    allow(event_2).to receive(:check_for_bogus_term_against).with([event_1]).and_return(nil)
    allow(event_1).to receive(:edge_for) do |graph,other_event|
      graph.add_edge(event_1, other_event)
    end
    allow(event_2).to receive(:edge_for) do |graph,other_event|
    end
    allow(event_1).to receive(:check_for_bogus_renewal_term_against).with(event_2).and_return(true)
    allow(EnrollmentAction::Base).to receive(:select_action_for).with([event_2]).and_return(resolved_action_2)
    allow(next_step).to receive(:call).with(resolved_action_2)
    allow(resolved_action_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
  end

  it "calls the next step without the first action" do
    expect(next_step).to receive(:call).with(resolved_action_2)
    subject.call([event_2, event_1])
  end

  it "appends the step to the history of the process" do
    expect(resolved_action_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
    subject.call([event_2, event_1])
  end

end

describe Handlers::EnrollmentEventEnrichHandler, "given:
- two events
- one which occurs before the other
- events are not adjacent" do
  let(:next_step) { double }
  let(:event_1) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => false, :drop_if_bogus_term! => false, :drop_if_bogus_renewal_term! => false) }
  let(:event_2) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => false, :drop_if_bogus_term! => false, :drop_if_bogus_renewal_term! => false) }
  let(:resolved_action_1) { instance_double(EnrollmentAction::Base) }
  let(:resolved_action_2) { instance_double(EnrollmentAction::Base) }

  subject { Handlers::EnrollmentEventEnrichHandler.new(next_step) }

  before :each do
    allow(event_1).to receive(:check_for_bogus_term_against).with([event_2]).and_return(nil)
    allow(event_2).to receive(:check_for_bogus_term_against).with([event_1]).and_return(nil)
    allow(event_1).to receive(:edge_for) do |graph,other_event|
      graph.add_edge(event_1, other_event)
    end
    allow(event_2).to receive(:edge_for) do |graph,other_event|
    end
    allow(event_1).to receive(:check_for_bogus_renewal_term_against).with(event_2).and_return(false)
    allow(event_1).to receive(:is_adjacent_to?).with(event_2).and_return(false)
    allow(EnrollmentAction::Base).to receive(:select_action_for).with([event_2]).and_return(resolved_action_2)
    allow(EnrollmentAction::Base).to receive(:select_action_for).with([event_1]).and_return(resolved_action_1)
    allow(resolved_action_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
    allow(resolved_action_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
    allow(next_step).to receive(:call).with(resolved_action_1)
    allow(next_step).to receive(:call).with(resolved_action_2)
  end

  it "calls the next step with the events properly ordered" do
    expect(next_step).to receive(:call).with(resolved_action_1)
    expect(next_step).to receive(:call).with(resolved_action_2)
    subject.call([event_2, event_1])
  end

  it "appends the step to the history of the first action" do
    expect(resolved_action_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
    subject.call([event_2, event_1])
  end

  it "appends the step to the history of the second action" do
    expect(resolved_action_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
    subject.call([event_2, event_1])
  end

end

describe Handlers::EnrollmentEventEnrichHandler, "given:
- two events
- one which occurs before the other
- events are adjacent" do
  let(:next_step) { double }
  let(:event_1) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => false, :drop_if_bogus_term! => false, :drop_if_bogus_renewal_term! => false) }
  let(:event_2) { instance_double(::ExternalEvents::EnrollmentEventNotification, :drop_if_bogus_plan_year! => false, :drop_if_bogus_term! => false, :drop_if_bogus_renewal_term! => false) }
  let(:resolved_action_1) { instance_double(EnrollmentAction::Base) }

  subject { Handlers::EnrollmentEventEnrichHandler.new(next_step) }

  before :each do
    allow(event_1).to receive(:check_for_bogus_term_against).with([event_2]).and_return(nil)
    allow(event_2).to receive(:check_for_bogus_term_against).with([event_1]).and_return(nil)
    allow(event_1).to receive(:edge_for) do |graph,other_event|
      graph.add_edge(event_1, other_event)
    end
    allow(event_2).to receive(:edge_for) do |graph,other_event|
    end
    allow(event_1).to receive(:check_for_bogus_renewal_term_against).with(event_2).and_return(false)
    allow(event_1).to receive(:is_adjacent_to?).with(event_2).and_return(true)
    allow(EnrollmentAction::Base).to receive(:select_action_for).with([event_1, event_2]).and_return(resolved_action_1)
    allow(resolved_action_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
    allow(next_step).to receive(:call).with(resolved_action_1)
  end

  it "searches for the correct action using both events in the correct order" do
    expect(EnrollmentAction::Base).to receive(:select_action_for).with([event_1, event_2]).and_return(resolved_action_1)
    subject.call([event_2, event_1])
  end

  it "calls the next step with the resolved action" do
    expect(next_step).to receive(:call).with(resolved_action_1)
    subject.call([event_2, event_1])
  end

  it "appends the step to the history of the action" do
    expect(resolved_action_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventEnrichHandler")
    subject.call([event_2, event_1])
  end
end
