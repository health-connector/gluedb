require "rails_helper"

# TODO: Refactor the EmployerEvent class - this spec demonstrates how
#       EmployerEvent has far too many responsibilties
describe EmployerEvent, "generating carrier files using .with_digest_payloads" do
  let(:employer_id_1) { "some employer id" }
  let(:employer_id_2) { "some other employer id" }

  let(:connection) { double }
  let(:the_time) { double }
  let(:carrier_1) { instance_double(Carrier) }
  let(:carrier_2) { instance_double(Carrier) }
  let(:carrier_file_1) { instance_double(EmployerEvents::CarrierFile, rendered_employers: [employer_id_1], empty?: false) }
  let(:carrier_file_2) { instance_double(EmployerEvents::CarrierFile, rendered_employers: [employer_id_2], empty?: false) }
  let(:event_1) { EmployerEvent.new(:employer_id => employer_id_1) }
  let(:event_2) { EmployerEvent.new(:employer_id => employer_id_2) }
  let(:event_renderer_1) { instance_double(EmployerEvents::Renderer) }
  let(:event_renderer_2) { instance_double(EmployerEvents::Renderer) }
  let(:edi_notifier) { instance_double(EmployerEvents::EmployerEdiContactInfoNotificationSet) }
  let(:carrier_1_render_xml) { double }
  let(:carrier_2_render_xml) { double }
  let(:carrier_1_render_result) { ["carrier_1_file_name", carrier_1_render_xml] }
  let(:carrier_2_render_result) { ["carrier_2_file_name", carrier_2_render_xml] }

  before(:each) do
    allow(Carrier).to receive(:all).and_return([carrier_1, carrier_2])
    allow(EmployerEvents::CarrierFile).to receive(:new).
      with(carrier_1).and_return(carrier_file_1)
    allow(EmployerEvents::CarrierFile).to receive(:new).
      with(carrier_2).and_return(carrier_file_2)
    allow(EmployerEvent).to receive(:ordered_events_since_time).and_return([event_1, event_2])
    allow(EmployerEvents::Renderer).to receive(:new).with(event_1).and_return(event_renderer_1)
    allow(EmployerEvents::Renderer).to receive(:new).with(event_2).and_return(event_renderer_2)
    allow(carrier_file_1).to receive(:render_event_using).with(event_renderer_1, event_1)
    allow(carrier_file_2).to receive(:render_event_using).with(event_renderer_1, event_1)
    allow(carrier_file_1).to receive(:render_event_using).with(event_renderer_2, event_2)
    allow(carrier_file_2).to receive(:render_event_using).with(event_renderer_2, event_2)
    allow(EmployerEvents::EmployerEdiContactInfoNotificationSet).to receive(:new).
      with(connection).and_return(edi_notifier)
    allow(carrier_file_1).to receive(:result).and_return(carrier_1_render_result)
    allow(carrier_file_2).to receive(:result).and_return(carrier_2_render_result)
    allow(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_1])
    allow(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_2])
  end

  it "sends a set of edi update notifications only for employers which had events rendered for a carrier" do
    expect(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_1])
    expect(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_2])
    EmployerEvent.with_digest_payloads(connection, the_time) do |a_carrier_payload|
    end
  end

  it "yields the rendered carrier xmls" do
    carrier_payloads = []
    EmployerEvent.with_digest_payloads(connection, the_time) do |a_carrier_payload|
      carrier_payloads << a_carrier_payload
    end
    expect(carrier_payloads).to include(carrier_1_render_xml)
    expect(carrier_payloads).to include(carrier_2_render_xml)
  end
end