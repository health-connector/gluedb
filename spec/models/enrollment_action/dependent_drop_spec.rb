require "rails_helper"

describe EnrollmentAction::DependentDrop, "given an enrollment event set that:
- has two enrollments
- the first enrollment is a termination of a member for for plan A
- the second enrollment is a start with one less member for plan A
- the second enrollment has less members" do

  let(:plan) { instance_double(Plan, :id => 1) }
  let(:different_plan) { instance_double(Plan, :id => 2) }

  let(:member_ids_1) { [1,2,3] }
  let(:member_ids_2) { [1,2] }

  let(:event_1) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => plan, :all_member_ids => member_ids_1) }
  let(:event_2) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => plan, :all_member_ids => member_ids_2) }
  let(:event_3) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => plan, :all_member_ids => member_ids_2) }
  let(:event_4) { instance_double(ExternalEvents::EnrollmentEventNotification, :existing_plan => different_plan, :all_member_ids => member_ids_2) }
  let(:event_set) { [event_1, event_2] }
  let(:non_qualifying_event_set_1) { [event_2, event_3] } # Same members, meaning no one was dropped
  let(:non_qualifying_event_set_2) { [event_1, event_4] } # Different plans. We are only dropping member, not changing plans

  subject { EnrollmentAction::DependentDrop }

  it "qualifies" do
    expect(subject.qualifies?(event_set)).to be_truthy
  end

  it "does not qualify because it has different plans" do
    expect(subject.qualifies?(non_qualifying_event_set_2)).to be_falsey
  end

  it "does not qualify because no members were dropped" do
    expect(subject.qualifies?(non_qualifying_event_set_1)).to be_falsey
  end

  it "does not qualify because chunk contains only one event" do
    expect(subject.qualifies?(event_set.take(1))).to be_falsey
  end
end

describe EnrollmentAction::DependentDrop, "given a qualified enrollment set, being persisted" do
  let(:member_primary) { instance_double(Openhbx::Cv2::EnrolleeMember, id: 1) }
  let(:member_secondary) { instance_double(Openhbx::Cv2::EnrolleeMember, id: 2) }
  let(:member_drop) { instance_double(Openhbx::Cv2::EnrolleeMember, id: 3) }


  let(:terminated_policy_cv) { instance_double(Openhbx::Cv2::Policy, :enrollees => [member_primary, member_secondary, member_drop])}
  let(:new_policy_cv) { instance_double(Openhbx::Cv2::Policy, :enrollees => [member_primary, member_secondary]) }
  let(:plan) { instance_double(Plan, :id => 1) }
  let(:policy) { instance_double(Policy, :hbx_enrollment_ids => [1,2,3]) }

  let(:dependent_drop_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :policy_cv => new_policy_cv,
    :existing_plan => plan,
    :all_member_ids => [1,2],
    :hbx_enrollment_id => 1
    ) }
  let(:termination_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :policy_cv => terminated_policy_cv,
    :existing_policy => policy,
    :all_member_ids => [1,2,3]
    ) }

  let(:policy_updater) { instance_double(ExternalEvents::ExternalPolicyMemberDrop) }

  subject do
    EnrollmentAction::DependentDrop.new(termination_event, dependent_drop_event)
  end

  before :each do

    allow(policy).to receive(:save).and_return(true)
    allow(ExternalEvents::ExternalPolicyMemberDrop).to receive(:new).with(termination_event.existing_policy, termination_event.policy_cv, [3]).and_return(policy_updater)
    allow(policy_updater).to receive(:persist).and_return(true)
  end

  it "successfully creates the new policy" do
    expect(subject.persist).to be_truthy
  end
end


describe EnrollmentAction::DependentDrop, "given a qualified enrollment set, being published" do
  let(:amqp_connection) { double }
  let(:termination_event_xml) { double }
  let(:event_xml) { double }
  let(:event_responder) { instance_double(::ExternalEvents::EventResponder, :connection => amqp_connection) }
  let(:enrollee_primary) { double(:m_id => 1, :coverage_start => :one_month_ago) }
  let(:enrollee_new) { double(:m_id => 2, :coverage_start => :one_month_ago) }

  let(:plan) { instance_double(Plan, :id => 1) }
  let(:policy) { instance_double(Policy, :enrollees => [enrollee_primary, enrollee_new], :eg_id => 1) }


  let(:dependent_drop_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :event_xml => event_xml,
    :all_member_ids => [1,2],
    :hbx_enrollment_id => 2
  ) }
  let(:termination_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :existing_policy => policy,
    :event_xml => termination_event_xml,
    :all_member_ids => [1,2,3],
    :event_responder => event_responder,
    :hbx_enrollment_id => 1,
    :employer_hbx_id => 3
  ) }
  let(:action_helper_result_xml) { double }

  let(:action_publish_helper) { instance_double(
    EnrollmentAction::ActionPublishHelper,
    :to_xml => action_helper_result_xml
  ) }

  before :each do
    allow(EnrollmentAction::ActionPublishHelper).to receive(:new).with(termination_event_xml).and_return(action_publish_helper)
    allow(action_publish_helper).to receive(:set_event_action).with("urn:openhbx:terms:v1:enrollment#change_member_terminate")
    allow(action_publish_helper).to receive(:set_policy_id).with(1).and_return(true)
    allow(action_publish_helper).to receive(:set_member_starts).with({ 1 => :one_month_ago, 2 => :one_month_ago })
    allow(action_publish_helper).to receive(:filter_affected_members).with([3]).and_return(true)
    allow(action_publish_helper).to receive(:replace_premium_totals).with([3]).and_return(event_xml)
    allow(action_publish_helper).to receive(:keep_member_ends).with([3])
    allow(subject).to receive(:publish_edi).with(amqp_connection, action_helper_result_xml, termination_event.hbx_enrollment_id, termination_event.employer_hbx_id)
  end

  subject do
    EnrollmentAction::DependentDrop.new(termination_event, dependent_drop_event)
  end

  it "publishes an event of type drop dependents" do
    expect(action_publish_helper).to receive(:set_event_action).with("urn:openhbx:terms:v1:enrollment#change_member_terminate")
    subject.publish
  end

  it "sets member start dates" do
    expect(action_publish_helper).to receive(:set_member_starts).with({ 1 => :one_month_ago, 2 => :one_month_ago })
    subject.publish
  end

  it "filter affected members on the dependent drop" do
    expect(action_publish_helper).to receive(:filter_affected_members).with([3]).and_return(true)
    subject.publish
  end

  it "corrects premium totals on the dependent drop" do
    expect(action_publish_helper).to receive(:replace_premium_totals).with([3]).and_return(event_xml)
    subject.publish
  end

  it "keep dropped member end dates before publishing" do
    expect(action_publish_helper).to receive(:keep_member_ends).with([3])
    subject.publish
  end

  it "publishes resulting xml to edi" do
    expect(subject).to receive(:publish_edi).with(amqp_connection, action_helper_result_xml, termination_event.hbx_enrollment_id, termination_event.employer_hbx_id)
    subject.publish
  end
end
