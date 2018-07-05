require "rails_helper"
require File.join(Rails.root,"app","data_migrations","broker_npn_change")

describe BrokerNpNChange, dbclean: :after_each do
  let(:given_task_name) { "broker_npn_change" }
  let(:broker_1) { FactoryGirl.create(:broker) }
  let(:broker_2) { FactoryGirl.create(:broker) }
  subject { BrokerNpNChange.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'the NPN change task' do 
    before(:each) do 
      ENV["old_npn"] = broker_1.npn
      ENV["new_npn"] = "123123"
    end

    it 'should change the Broker NPN if there are no other identical NPNs' do 
      subject.migrate
      broker_1.reload
      expect(broker_1.npn).to eql "123123"
    end

    it 'should not change the NPN if there is an existing NPNs' do 
      ENV["new_npn"] = broker_2.npn
      subject.migrate
      expect(broker_1.npn).not_to eql broker_2.npn
    end
  end
end