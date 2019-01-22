require 'rails_helper'

describe EnrollmentAction::CobraReinstate, "given:
- 2 events
" do

  let(:event_1) { instance_double(ExternalEvents::EnrollmentEventNotification) } 
  let(:event_2) { instance_double(ExternalEvents::EnrollmentEventNotification) }

  subject { EnrollmentAction::CobraReinstate }

  it "does not qualify" do
    expect(subject.qualifies?([event_1, event_2])).to be_false
  end

end

describe EnrollmentAction::CobraReinstate, "given:
- has one enrollment
- that enrollment is a termination
" do

  let(:event_1) { instance_double(ExternalEvents::EnrollmentEventNotification, is_termination?: true) }

  subject { EnrollmentAction::CobraReinstate }

  it "does not qualify" do
    expect(subject.qualifies?([event_1])).to be_false
  end
end

describe EnrollmentAction::CobraReinstate, "given:
- has one enrollment
- that enrollment is not a termination
- that enrollment is not cobra
" do

  let(:event_1) { instance_double(ExternalEvents::EnrollmentEventNotification, is_termination?: false, is_cobra?: false) }

  subject { EnrollmentAction::CobraReinstate }

  it "does not qualify" do
    expect(subject.qualifies?([event_1])).to be_false
  end
end

describe EnrollmentAction::CobraReinstate, "given:
- has one enrollment
- that enrollment is not a termination
- that enrollment is cobra
- there is an already terminated corresponding shop policy
" do

  let(:event_1) { instance_double(ExternalEvents::EnrollmentEventNotification, is_termination?: false, is_cobra?: true) }

  subject { EnrollmentAction::CobraReinstate }

  before :each do
    allow(subject).to receive(:same_carrier_reinstatement_candidates).with(event_1).and_return([double])
  end

  it "qualifies" do
    expect(subject.qualifies?([event_1])).to be_true
  end
end

describe EnrollmentAction::CobraReinstate, "with an cobra reinstate enrollment event, being persisted" do
  let(:policy_cv) { instance_double(Openhbx::Cv2::Policy) }
  let(:enrollment_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :policy_cv => policy_cv
  ) }
  let(:existing_policy) { instance_double(Policy) }
  let(:policy_updater) { instance_double(ExternalEvents::ExternalPolicyCobraSwitch) }

  subject do
    EnrollmentAction::CobraReinstate.new(nil, enrollment_event)
  end

  before :each do
    allow(subject).to receive(:same_carrier_reinstatement_candidates).with(enrollment_event).and_return([existing_policy])
    allow(ExternalEvents::ExternalPolicyCobraSwitch).to receive(:new).with(policy_cv, existing_policy).and_return(policy_updater)
    allow(policy_updater).to receive(:persist).and_return(true)
  end

  it "successfully creates the new policy" do
    expect(subject.persist).to be_truthy
  end
end

describe EnrollmentAction::CobraReinstate, "with an cobra reinstate enrollment event, being published" do
  let(:amqp_connection) { double }
  let(:event_xml) { double }
  let(:event_responder) { instance_double(::ExternalEvents::EventResponder, :connection => amqp_connection) }
  let(:workflow_id) { "SOME WORKFLOW ID" }
  let(:enrollment_event) { instance_double(
    ::ExternalEvents::EnrollmentEventNotification,
    :event_responder => event_responder,
    :event_xml => event_xml,
    :hbx_enrollment_id => hbx_enrollment_id,
    :employer_hbx_id => employer_hbx_id,
    :workflow_id => workflow_id
  ) }
  let(:action_publish_helper) { instance_double(
    EnrollmentAction::ActionPublishHelper,
    :to_xml => action_helper_result_xml
  ) }

  let(:action_helper_result_xml) { double }
  let(:hbx_enrollment_id) { double }
  let(:employer_hbx_id) { double }
  let(:existing_policy) { instance_double(Policy, :enrollees => existing_enrollees, :eg_id => "enrollment_group_id") }
  let(:subscriber) { instance_double(Enrollee, :m_id => "1", :coverage_start => "coverage_start_date") }
  let(:existing_enrollees) { [subscriber] }

  subject do
    the_action = EnrollmentAction::CobraReinstate.new(nil, enrollment_event)
    the_action.existing_policy = existing_policy
    the_action
  end

  before :each do
    allow(EnrollmentAction::ActionPublishHelper).to receive(:new).with(event_xml).and_return(action_publish_helper)
    allow(action_publish_helper).to receive(:set_event_action).with("urn:openhbx:terms:v1:enrollment#reinstate_enrollment")
    allow(action_publish_helper).to receive(:set_market_type).with("urn:openhbx:terms:v1:aca_marketplace#cobra")
    allow(action_publish_helper).to receive(:keep_member_ends).with([])
    allow(action_publish_helper).to receive(:set_member_starts).with({"1" => "coverage_start_date"})
    allow(action_publish_helper).to receive(:set_policy_id).with("enrollment_group_id")
    allow(subject).to receive(:publish_edi).with(amqp_connection, action_helper_result_xml, hbx_enrollment_id, employer_hbx_id, workflow_id)
  end

  it "publishes an event of type reenroll enrollment" do
    expect(action_publish_helper).to receive(:set_event_action).with("urn:openhbx:terms:v1:enrollment#reinstate_enrollment")
    subject.publish
  end

  it "publishes set market type cobra" do
    expect(action_publish_helper).to receive(:set_market_type).with("urn:openhbx:terms:v1:aca_marketplace#cobra")
    subject.publish
  end

  it "sets the policy id" do
    expect(action_publish_helper).to receive(:set_policy_id).with("enrollment_group_id")
    subject.publish
  end

  it "sets the existing member start dates" do
    expect(action_publish_helper).to receive(:set_member_starts).with({"1" => "coverage_start_date"})
    subject.publish
  end

  it "clears all member end dates before publishing" do
    expect(action_publish_helper).to receive(:keep_member_ends).with([])
    subject.publish
  end

  it "publishes the resulting xml to edi" do
    expect(subject).to receive(:publish_edi).with(amqp_connection, action_helper_result_xml, hbx_enrollment_id, employer_hbx_id, workflow_id)
    subject.publish
  end
end
