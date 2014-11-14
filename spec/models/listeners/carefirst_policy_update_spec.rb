require 'rails_helper'

describe Listeners::CarefirstPolicyUpdate do
  let(:controller) { double(:respond_to_failure => nil, :respond_to_success => nil) }
  let(:subject) { Listeners::CarefirstPolicyUpdate.new(controller, transmission_factory, transaction_factory, file_factory) }
  let(:transmission_factory) { double({:find_or_create_transmission => transmission}) }
  let(:transaction_factory) { double({:create_transaction => nil}) }
  let(:file_factory) { double({:new => file_string}) }
  let(:transmission) { double({:id => transmission_id }) }
  let(:transmission_id) { "12343" }
  let(:batch_id) { "alksdjfleijsdisfe" }
  let(:file_name) { "some_file_or_another.csv" }
  let(:submitted_by) { double }
  let(:carrier_id) { double }
  let(:non_authority_member_id) { "alksdjfioef" }

  let(:transmission_properties) {
   {
     :carrier_id => carrier_id,
     :file_name => file_name,
     :submitted_by => submitted_by,
     :batch_id => batch_id
   }
  }

  let(:batch_index) { "5" }
  let(:policy_id) { "lkajsdklfjef" }
  let(:body) { double }
  let(:file_string) { double }
  let(:fs_name) {
    batch_id + "_" + batch_index.to_s + "_" + file_name
  }

  describe "which fails" do
    let(:failure_messages) { ["Member " + non_authority_member_id + " is not the authority member"] }
    let(:transaction_properties) {
      {
        :csv_transmission_id => transmission_id,
        :policy_id => policy_id,
        :batch_index => batch_index,
        :error_list => failure_messages,
        :body => file_string,
        :submitted_at => nil
      }
    }
    let(:failure_details) {
      transmission_properties.merge({
        :policy_id => policy_id,
        :batch_index => batch_index,
        :error_list => failure_messages,
        :body => body
      })
    }

    before(:each) do
      subject.non_authority_member(non_authority_member_id)
    end

    it "should notify the controller" do
      expect(controller).to receive(:respond_to_failure).with(failure_messages)
      subject.fail(failure_details)
    end

    it "should create a new body for the data" do
      expect(file_factory).to receive(:new).with(fs_name, body).and_return(file_string)
      subject.fail(failure_details)
    end

    it "should create a new CsvTransmission" do
      expect(transmission_factory).to receive(:find_or_create_transmission).with(transmission_properties)
      subject.fail(failure_details)
    end

    it "should create a new CsvTransaction" do
      expect(transaction_factory).to receive(:create_transaction).with(transaction_properties)
      subject.fail(failure_details)
    end
  end

  describe "which succeeds" do
    let(:success_details) {
      transmission_properties.merge({
        :policy_id => policy_id,
        :batch_index => batch_index,
        :body => body,
        :error_list => []
      })
    }

    let(:transaction_properties) {
      {
        :csv_transmission_id => transmission_id,
        :policy_id => policy_id,
        :batch_index => batch_index,
        :error_list => [],
        :body => file_string,
        :submitted_at => nil
      }
    }

    it "should notify the controller" do
      expect(controller).to receive(:respond_to_success)
      subject.success(success_details)
    end

    it "should create a new body for the data" do
      expect(file_factory).to receive(:new).with(fs_name, body).and_return(file_string)
      subject.success(success_details)
    end

    it "should create a new CsvTransmission" do
      expect(transmission_factory).to receive(:find_or_create_transmission).with(transmission_properties)
      subject.success(success_details)
    end

    it "should create a new CsvTransaction" do
      expect(transaction_factory).to receive(:create_transaction).with(transaction_properties)
      subject.success(success_details)
    end
  end
end
