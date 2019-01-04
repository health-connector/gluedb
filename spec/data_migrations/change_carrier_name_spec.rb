require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_carrier_name")

describe ChangeCarrierName, dbclean: :after_each do
  let(:given_task_name) { "change_carrier_name" }
  let(:carrier) { FactoryGirl.create(:carrier, name:"Old Carrier") }
  let(:updated_name)  {"New carrier"}

  subject { ChangeCarrierName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'the carrier name change' do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("hbx_carrier_id").and_return(carrier.hbx_carrier_id)
      allow(ENV).to receive(:[]).with("new_name").and_return(updated_name)
    end

    it 'should change the carrier name' do 
      subject.migrate
      carrier.reload
      expect(carrier.name).to eql "New carrier"
    end
  end
  
end