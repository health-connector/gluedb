require "rails_helper"

describe Listeners::IndividualEventListener do
  let(:channel) { double }
  let(:subject) { Listeners::IndividualEventListener.new(channel, nil) }
  let(:individual_id) { "an individual id" }
  let(:props) { double(:headers => { :individual_id => individual_id }) }
  let(:body) { "" }
  let(:delivery_tag) { "an amqp delivery tag" }
  let(:di) { double(:delivery_tag => delivery_tag) }
  let(:channel) { double }

  describe "contacting the 'callback' service to get the full individual resource" do
    let(:other_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.unknown_error",
      :headers => {
        :return_status => "500",
        :individual_id => individual_id 
      }
    } }

    let(:not_found_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.resource_not_found",
      :headers => {
        :return_status => "404",
        :individual_id => individual_id 
      }
    } }

    let(:timeout_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.resource_timeout",
      :headers => {
        :return_status => "503",
        :individual_id => individual_id 
      }
    } }

    it "should broadcast an error and requeue the message if the request times out" do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["503", nil])
      expect(channel).to receive(:nack).with(delivery_tag, false, true)
      expect(subject).to receive(:broadcast_event).with(timeout_error_properties, "")
      subject.on_message(di, props, body)
    end

    it "should broadcast an error and consume the message if the resource does not exist" do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["404", nil])
      expect(channel).to receive(:ack).with(delivery_tag, false)
      expect(subject).to receive(:broadcast_event).with(not_found_error_properties, "")
      subject.on_message(di, props, body)
    end

    it "should broadcast an error and requeue the message if the there is any other type of error" do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["500", "some string about something"])
      expect(channel).to receive(:nack).with(delivery_tag, false, true)
      expect(subject).to receive(:broadcast_event).with(other_error_properties, "some string about something")
      subject.on_message(di, props, body)
    end
  end

  describe "given a new individual" do
    let(:new_individual_resource) {
      double(:to_s => "a body value for the resource")
    }

    let(:individual_creation_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.individual_created",
      :headers => {
        :return_status => "422",
        :individual_id => individual_id 
      }
    } }

    let(:individual_created_properties) { {
      :routing_key => "info.application.gluedb.individual_update_event_listener.individual_created",
      :headers => {
        :return_status => "200",
        :individual_id => individual_id 
      }
    } }

    let(:individual_change_set) {
      double(:individual_exists? => false, :create_individual_resource => creation_result, :full_error_messages => full_error_messages)
    }

    let(:full_error_messages) { ["a", "list of", "error messages"] }

    before :each do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["200", new_individual_resource])
      allow(ChangeSets::IndividualChangeSet).to receive(:new).with(new_individual_resource).and_return(individual_change_set)
    end

    context "given a valid individual" do
      let(:creation_result) { true }

      it "should create that individual" do
        expect(channel).to receive(:ack).with(delivery_tag, false)
        expect(subject).to receive(:broadcast_event).with(individual_created_properties, "a body value for the resource")
        subject.on_message(di, props, body)
      end
    end

    context "given an invalid individual" do
      let(:creation_result) { false }

      it "should create that individual" do
        expect(channel).to receive(:ack).with(delivery_tag, false)
        expect(subject).to receive(:broadcast_event).with(individual_creation_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
        subject.on_message(di, props, body)
      end
    end
  end

  describe "given an individual which already exists" do
    describe "and the individual has no active policies" do
      it "should simply update that individual's record"
    end

    describe "and the individual has active policies" do
      describe "and there is a change to name" do
        describe "and there is also a change of address" do
          it "should update only the name portion of the individual's record"
          it "should send out policy updates via EDI with reason 'change of identifying information'"
          it "should nack the message for re-delivery"
        end

        describe "and there are no other changes to the person's information" do
          it "should update the individual's record"
          it "should send out policy updates via EDI with reason 'change of identifying information'"
        end
      end
    end
  end
end
