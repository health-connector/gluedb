require "rails_helper"

describe ChangeSets::IdentityChangeTransmitter do
  let(:affected_member) { instance_double(::BusinessProcesses::AffectedMember, :member_id => affected_member_id) }
  let(:policy) { instance_double(Policy, :enrollees => [], :active_member_ids => active_member_ids) }
  let(:event_kind) { "some event kind" }
  let(:active_member_ids) { ["member id 1", "member id 2"] }
  let(:enrollees) { [] }

  subject { ChangeSets::IdentityChangeTransmitter.new(affected_member, policy, event_kind) }

  context "when the affected member is not an active member" do
    let(:affected_member_id) { "member id 3" }

    it "does not publish" do
      expect(ApplicationController).not_to receive(:new)
      subject.publish
    end
  end

  context "publishes when the affected member is an active member" do
    let(:affected_member_id) { "member id 2" }
    let(:renderer_controller) { double }
    let(:template_result) { double }
    let(:enrollment_event_transmitter) { instance_double(::Services::EnrollmentEventTransmitter) }
    let(:amqp_connection) { double }
    let(:transaction_id) { double }
  
    before(:each) do
      allow(ApplicationController).to receive(:new).and_return(renderer_controller)
      allow(renderer_controller).to receive(:render_to_string).with(
         :layout => "enrollment_event",
         :partial => "enrollment_events/enrollment_event",
         :format => :xml,
         :locals => {
           :affected_members => [affected_member],
           :policy => policy,
           :enrollees => enrollees,
           :event_type => event_kind,
           :transaction_id => transaction_id
         }
      ).and_return(template_result)
      allow(::Services::EnrollmentEventTransmitter).to receive(:new).and_return(enrollment_event_transmitter)
      allow(::AmqpConnectionProvider).to receive(:start_connection).and_return(amqp_connection)
      allow(amqp_connection).to receive(:close)
      allow(subject).to receive(:transaction_id).and_return(transaction_id)
    end

    it "publishes the rendered template" do
      expect(enrollment_event_transmitter).to receive(:call).with(amqp_connection, template_result)
      subject.publish
    end
  end
end
