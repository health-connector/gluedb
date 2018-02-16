require "rails_helper"

describe Amqp::EventBroadcaster, "with pooled instances" do
  let(:connection) { double }

  before :each do
    allow(AmqpConnectionProvider).to receive(:start_connection).and_return(connection)
    allow(connection).to receive(:close)
  end

  it "raises an error if you attempt re-entrancy" do
    test_proc = Proc.new do
      begin
      Amqp::EventBroadcaster.cache_local_instance do 
        Amqp::EventBroadcaster.cache_local_instance do
        end
      end
      ensure
        Thread.current[:__local_amqp_event_broadcaster_instance] = nil
      end
    end
    expect(&test_proc).to raise_error(ThreadError)
  end

  it "closes the connection after the block executes" do
    expect(connection).to receive(:close)
    Amqp::EventBroadcaster.cache_local_instance do
    end
  end

  it "uses the pooled broadcaster when asked for a cached instance" do
      Amqp::EventBroadcaster.cache_local_instance do 
        first_broadcaster = nil
        second_broadcaster = nil
        Amqp::EventBroadcaster.with_broadcaster do |eb1|
          first_broadcaster = eb1
        end
        Amqp::EventBroadcaster.with_broadcaster do |eb2|
          second_broadcaster = eb2
        end
        expect(first_broadcaster.object_id).to eq second_broadcaster.object_id
      end
  end
end
