require "rails_helper"

describe ::ExternalEvents::EnrollmentEventNotificationFilters::AlreadyProcessedTermination, "given:
- an enrollment which is is an already processed termination
- an enrollment which is not an already processed termination
" do

  let(:already_processed_term) { instance_double(ExternalEvents::EnrollmentEventNotification, :drop_if_already_processed_termination! => true) }
  let(:unprocessed_termination) { instance_double(ExternalEvents::EnrollmentEventNotification, :drop_if_already_processed_termination! => false) }

  let(:events) { [already_processed_term, unprocessed_termination] }

  it "filters out the already processed termination" do
    expect(subject.filter(events)).not_to include(already_processed_term)
  end

  it "keeps the unprocessed action" do
    expect(subject.filter(events)).to include(unprocessed_termination)
  end
end
