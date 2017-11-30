require "rails_helper"

describe Handlers::EnrollmentEventReduceHandler, "given an event that has already been processed" do
  let(:next_step) { double }
  let(:filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent) }
  let(:event) { instance_double(::ExternalEvents::EnrollmentEventNotification) }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent).to receive(:new).and_return(filter)
    allow(filter).to receive(:filter).with([event]).and_return([])
  end

  it "does not go on to the next step" do
    expect(next_step).not_to receive(:call)
    subject.call([event])
  end
end

describe Handlers::EnrollmentEventReduceHandler, "given an event that has already been processed" do
  let(:next_step) { double }
  let(:filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent) }
  let(:event) { instance_double(::ExternalEvents::EnrollmentEventNotification) }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent).to receive(:new).and_return(filter)
    allow(filter).to receive(:filter).with([event]).and_return([])
  end

  it "does not go on to the next step" do
    expect(next_step).not_to receive(:call)
    subject.call([event])
  end
end

describe Handlers::EnrollmentEventReduceHandler, "given a termination with no end" do
  let(:next_step) { double }
  let(:filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent) }
  let(:event) { instance_double(::ExternalEvents::EnrollmentEventNotification) }
  let(:bad_term_filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd) }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent).to receive(:new).and_return(filter)
    allow(filter).to receive(:filter).with([event]).and_return([event])
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd).to receive(:new).and_return(bad_term_filter)
    allow(bad_term_filter).to receive(:filter).with([event]).and_return([])
  end

  it "does not go on to the next step" do
    expect(next_step).not_to receive(:call)
    subject.call([event])
  end
end

describe Handlers::EnrollmentEventReduceHandler, "given a termination which has already been processed" do
  let(:next_step) { double }
  let(:already_processed_filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent) }
  let(:filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedTermination) }
  let(:event) { instance_double(::ExternalEvents::EnrollmentEventNotification) }
  let(:bad_term_filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd) }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedEvent).to receive(:new).and_return(already_processed_filter)
    allow(already_processed_filter).to receive(:filter).with([event]).and_return([event])
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd).to receive(:new).and_return(bad_term_filter)
    allow(bad_term_filter).to receive(:filter).with([event]).and_return([event])
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedTermination).to receive(:new).and_return(filter)
    allow(filter).to receive(:filter).with([event]).and_return([])
  end

  it "does not go on to the next step" do
    expect(next_step).not_to receive(:call)
    subject.call([event])
  end
end

describe Handlers::EnrollmentEventReduceHandler, "given:
- 3 notifications
- 2 of which should reduce"  do
  
  let(:non_duplicate_notification) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 1, :drop_if_marked! => false, :bucket_id => 5, :hbx_enrollment_id => 1, :enrollment_action => "a", :drop_if_already_processed! => false) }
  let(:duplicate_notification_1) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => true, :hbx_enrollment_id => 2, :enrollment_action => "b", :drop_if_already_processed! => false) }
  let(:duplicate_notification_2) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => true, :hbx_enrollment_id => 3, :enrollment_action => "c", :drop_if_already_processed! => false) }
  let(:notifications) { [duplicate_notification_1, duplicate_notification_2, non_duplicate_notification] }
  let(:bad_term_filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd) }
  let(:dupe_termination_filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedTermination) }

  let(:next_step) { double("The next step in the pipeline") }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedTermination).to receive(:new).and_return(dupe_termination_filter)
    allow(dupe_termination_filter).to receive(:filter).with(notifications).and_return(notifications)
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd).to receive(:new).and_return(bad_term_filter)
    allow(bad_term_filter).to receive(:filter).with(notifications).and_return(notifications)
    allow(next_step).to receive(:call).with([non_duplicate_notification])
    allow(duplicate_notification_1).to receive(:check_and_mark_duplication_against).with(duplicate_notification_2)
    allow(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
  end

  it "sends along 1 bucket with the non-reduced enrollment notification" do
    expect(next_step).to receive(:call).with([non_duplicate_notification])
    subject.call(notifications)
  end

  it "updates the business process history of the non-duplicate enrollment" do
    expect(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end

end

describe Handlers::EnrollmentEventReduceHandler, "given:
- 3 notifications
- 2 of which should be bucketed together"  do
  
  let(:non_duplicate_notification) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 1, :drop_if_marked! => false, :bucket_id => 5, :hbx_enrollment_id => 1, :enrollment_action => "a", :drop_if_already_processed! => false) }
  let(:same_bucket_notification_1) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => false, :bucket_id => 4, :hbx_enrollment_id => 2, :enrollment_action => "b", :drop_if_already_processed! => false) }
  let(:same_bucket_notification_2) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => false, :bucket_id => 4, :hbx_enrollment_id => 3, :enrollment_action => "c", :drop_if_already_processed! => false) }
  let(:notifications) { [same_bucket_notification_1, same_bucket_notification_2, non_duplicate_notification] }
  let(:bad_term_filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd) }
  let(:dupe_termination_filter) { instance_double(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedTermination) }

  let(:next_step) { double("The next step in the pipeline") }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedTermination).to receive(:new).and_return(dupe_termination_filter)
    allow(dupe_termination_filter).to receive(:filter).with(notifications).and_return(notifications)
    allow(::ExternalEvents::EnrollmentEventNotificationFilters::TerminationWithoutEnd).to receive(:new).and_return(bad_term_filter)
    allow(bad_term_filter).to receive(:filter).with(notifications).and_return(notifications)
    allow(next_step).to receive(:call).with([non_duplicate_notification])
    allow(next_step).to receive(:call).with([same_bucket_notification_1, same_bucket_notification_2])
    allow(same_bucket_notification_1).to receive(:check_and_mark_duplication_against).with(same_bucket_notification_2)
    allow(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    allow(same_bucket_notification_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    allow(same_bucket_notification_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
  end

  it "sends along a bucket with the single enrollment notification" do
    expect(next_step).to receive(:call).with([non_duplicate_notification])
    subject.call(notifications)
  end

  it "sends along a bucket with the same-bucket enrollment notifications" do
    expect(next_step).to receive(:call).with([same_bucket_notification_1, same_bucket_notification_2])
    subject.call(notifications)
  end

  it "updates the business process history of the single bucket enrollment" do
    expect(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end

  it "updates the business process history of the first group bucket enrollment" do
    expect(same_bucket_notification_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end

  it "updates the business process history of the second group bucket enrollment" do
    expect(same_bucket_notification_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end
end
