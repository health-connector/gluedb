require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_policy_broker")

describe ChangePolicyBroker, dbclean: :after_each do 
  let(:given_task_name) { "change_policy_broker" }
  let(:policy) { FactoryGirl.create(:policy) }
  let(:broker) { FactoryGirl.create(:broker) }
  subject { ChangePolicyBroker.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the broker" do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("broker_npn").and_return(broker.npn)
    end

    it 'should change the broker' do 
      subject.migrate
      policy.reload
      expect(policy.broker_id).to eq broker._id
    end
    
  end
end