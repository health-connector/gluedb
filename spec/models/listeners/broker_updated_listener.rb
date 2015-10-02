require 'rails_helper'

describe Listeners::BrokerUpdatedListener do
  let(:broker) { double }
  let(:broker_hbx_id) { "a broker npn" }
  let(:message_body) { "" }
  let(:message_properties) { double(:headers => message_headers) }
  let(:message_headers) { { :broker_id => broker_hbx_id } }
  let(:channel) { double }
  let(:queue) { double }
  let(:delivery_info) { double(:delivery_tag => "a message tag") }
  let(:expected_broker_properties) { { } }

  subject { Listeners::BrokerUpdatedListener.new(channel, queue) }

  before :each do
    allow(Broker).to receive(:by_npn).with(broker_hbx_id).and_return(matching_brokers)
    allow(channel).to receive(:acknowledge).with("a message tag", false)
  end

  describe "given an broker which doesn't exist" do
    let(:matching_brokers) { [] }
    it "should create that broker" do
      expect(Broker).to receive(:create!).with(expected_broker_properties)
      subject.on_message(delivery_info, message_properties, message_body)
    end
  end

  describe "given an broker which exists" do
    let(:matching_brokers) { [broker] }
    it "should update that broker" do
      expect(broker).to receive(:update_attributes).with(expected_broker_properties)
      subject.on_message(delivery_info, message_properties, message_body)
    end
  end
end
