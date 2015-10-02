require 'rails_helper'

describe Listeners::BrokerUpdatedListener do
  let(:broker) { double }
  let(:broker_hbx_id) { "a broker npn" }

  before :each do
    allow(Broker).to receive(:by_npn).with(broker_hbx_id).and_return(matching_brokers)
  end

  describe "given an broker which doesn't exist" do
    let(:matching_brokers) { [] }
    it "should create that broker"
  end

  describe "given an broker which exists" do
    let(:matching_brokers) { [broker] }
    it "should update that broker"
  end
end
