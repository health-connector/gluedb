require "rails_helper"

describe EnrollmentAction::DependentDrop, "given an enrollment event set that:
- has two enrollments
- the first enrollment is a cancel for plan A
- the second enrollment is a start for plan A
- the second enrollment has less members" do

  let(:plan) { instance_double(Plan, :id => 1) }

  let(:member_ids_1) { [1,2,3] }
  let(:member_ids_2) { [1,2] }

  let(:event_1) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => plan, :all_member_ids => member_ids_1) }
  let(:event_2) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => plan, :all_member_ids => member_ids_2) }
  let(:event_set) { [event_1, event_2] }

  subject { EnrollmentAction::DependentDrop }

  it "qualifies" do
    expect(subject.qualifies?(event_set)).to be_truthy
  end
end
