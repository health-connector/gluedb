require "rails_helper"
require "byebug"

describe EnrollmentAction::PlanChangeDependentAdd, "given an enrollment event set that:
- has two enrollments
- the first enrollment is a cancel for plan A
- the second enrollment is a start for plan A
- the second enrollment has more members
- the second enrollment has a different product" do

  let(:old_plan) { instance_double(Plan, :id => 1, :carrier_id => "1234") }
  let(:new_plan) { instance_double(Plan, :id => 2, :carrier_id => "1234") }
  let(:new_plan_different_carrier) { instance_double(Plan, :id => 3, :carrier_id => "4567") }

  let(:member_ids_1) { [1,2] }
  let(:member_ids_2) { [1,2,3] }

  let(:event_1) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => old_plan, :all_member_ids => member_ids_1) }
  let(:event_2) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => new_plan, :all_member_ids => member_ids_2) }
  let(:event_3) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => new_plan_different_carrier, :all_member_ids => member_ids_2) }
  let(:event_set) { [event_1, event_2] }
  let(:event_set_different_carrier) { [event_1, event_3] }

  subject { EnrollmentAction::PlanChangeDependentAdd }

  it "qualifies" do
    expect(subject.qualifies?(event_set)).to be_truthy
  end

  it "does not qualify because of different carriers" do
    expect(subject.qualifies?(event_set_different_carrier)).to be_falsey
  end

  it "does not qualify because chunk contains only one event" do
    expect(subject.qualifies?(event_set.take(1))).to be_falsey
  end

end

describe EnrollmentAction::PlanChangeDependentAdd, "given a qualified enrollment set, being persisted" do
  let(:member_primary) { instance_double(Openhbx::Cv2::EnrolleeMember, id: 1) }
  let(:member_secondary) { instance_double(Openhbx::Cv2::EnrolleeMember, id: 2) }
  let(:member_new) { instance_double(Openhbx::Cv2::EnrolleeMember, id: 3) }
  let(:enrollee_primary) { instance_double(::Openhbx::Cv2::Enrollee, :member => member_primary) }
  let(:enrollee_secondary) { instance_double(::Openhbx::Cv2::Enrollee, :member => member_secondary) }
  let(:enrollee_new) { instance_double(::Openhbx::Cv2::Enrollee, :member => member_new) }

  let(:terminated_policy_cv) { instance_double(Openhbx::Cv2::Policy, :enrollees => [enrollee_primary, enrollee_secondary])}
  let(:new_policy_cv) { instance_double(Openhbx::Cv2::Policy, :enrollees => [enrollee_primary, enrollee_secondary, enrollee_new]) }
  let(:plan) { instance_double(Plan, :id => 1) }
  let(:policy) { instance_double(Policy, :hbx_enrollment_ids => [1,2]) }
  let(:primary_db_record) { instance_double(ExternalEvents::ExternalMember, :persist => true) }
  let(:secondary_db_record) { instance_double(ExternalEvents::ExternalMember, :persist => true) }
  let(:new_db_record) { instance_double(ExternalEvents::ExternalMember, :persist => true) }

  let(:dependent_add_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :policy_cv => new_policy_cv,
    :existing_plan => plan,
    :all_member_ids => [1,2,3],
    :hbx_enrollment_id => 3
    ) }
  let(:termination_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :policy_cv => terminated_policy_cv,
    :existing_policy => policy,
    :all_member_ids => [1,2]
    ) }

  let(:policy_updater) { instance_double(ExternalEvents::ExternalPolicy) }

  subject do
    EnrollmentAction::PlanChangeDependentAdd.new(termination_event, dependent_add_event)
  end

  before :each do
    allow(ExternalEvents::ExternalMember).to receive(:new).with(member_primary).and_return(primary_db_record)
    allow(ExternalEvents::ExternalMember).to receive(:new).with(member_secondary).and_return(secondary_db_record)
    allow(ExternalEvents::ExternalMember).to receive(:new).with(member_new).and_return(new_db_record)

    allow(ExternalEvents::ExternalPolicy).to receive(:new).with(new_policy_cv, plan).and_return(policy_updater)
    allow(policy_updater).to receive(:persist).and_return(true)
    allow(termination_event.existing_policy).to receive(:terminate_as_of).and_return(true)
    allow(termination_event).to receive(:subscriber_end).and_return(true)
  end

  it "successfully creates the new policy" do
    expect(subject.persist).to be_truthy
  end
end
