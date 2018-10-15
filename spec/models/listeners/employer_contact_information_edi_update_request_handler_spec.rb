require 'rails_helper'

describe Listeners::EmployerContactInformationEdiUpdateRequestHandler do
  let(:message_headers) { { :employer_id => employer_hbx_id } }
  let(:message_body) { "" }
  let(:message_tag) {"Rspec Channel Delivery info"}
  let(:connection) { double }
  let(:channel) { double(:connection => connection) }
  let(:queue) { double }
  let!(:employer) {FactoryGirl.create(:employer, hbx_id:'212344333')}
  let(:delivery_info) { double(:delivery_tag => "Rspec Channel Delivery info")}
  let!(:message_properties) { double("PROPERTIES", headers: message_headers, :timestamp => nil)}
  let(:employer_hbx_id) { "212344333" }
  let(:event_broadcaster) { instance_double(::Amqp::EventBroadcaster) }
  let(:test) { double("Publishers::EmployerEnrollmentNotification")}
  let(:expected_employer_properties) do
    {:routing_key=> "info.application.glue.employer_contact_information_edi_update_request_handler.request_processed",
     :headers=>{"employer_id"=>employer_hbx_id, :return_status=>"200"}}
   end

  subject { Listeners::EmployerContactInformationEdiUpdateRequestHandler.new(channel, queue) }
  
  before do
    allow(Publishers::EmployerEnrollmentNotification).to receive(:new).and_return(test)
    allow(test).to receive(:process_enrollments_for_edi).and_return("rspec")
    allow(::Amqp::EventBroadcaster).to receive(:new).with(connection).and_return(event_broadcaster)
    allow(event_broadcaster).to receive(:broadcast).and_return(true)
    allow(channel).to receive(:acknowledge).with(message_tag, false)
    subject.on_message(delivery_info, message_properties, message_body)
  end
 
  it 'broadcasts the message' do
    expect(event_broadcaster).to have_received(:broadcast).with(expected_employer_properties, message_body)
  end

  it "sends acknowledgement to the channel" do
    expect(channel).to have_received(:acknowledge).with(message_tag, false)
  end
end
