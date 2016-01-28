require "rails_helper"

describe Listeners::IndividualEventListener do
  let(:timestamp) { Time.mktime(2008,11,13,0,0,0) }
  let(:channel) { double }
  let(:subject) { Listeners::IndividualEventListener.new(channel, nil) }
  let(:individual_id) { "an individual id" }
  let(:props) { double(:headers => { :individual_id => individual_id }) }
  let(:body) { "" }
  let(:delivery_tag) { "an amqp delivery tag" }
  let(:di) { double(:delivery_tag => delivery_tag) }
  let(:channel) { double }

  before :each do
    allow(Time).to receive(:now).and_return(timestamp)
  end

  describe "contacting the 'callback' service to get the full individual resource" do
    let(:other_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.unknown_error",
      :headers => {
        :return_status => "500",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:not_found_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.resource_not_found",
      :headers => {
        :return_status => "404",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:timeout_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.resource_timeout",
      :headers => {
        :return_status => "503",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp.to_i
      }
    } }

    it "should broadcast an error and requeue the message if the request times out" do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["503", nil])
      expect(channel).to receive(:reject).with(delivery_tag, true)
      expect(subject).to receive(:broadcast_event).with(timeout_error_properties, "")
      subject.on_message(di, props, body)
    end

    it "should broadcast an error and consume the message if the resource does not exist" do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["404", nil])
      expect(channel).to receive(:ack).with(delivery_tag, false)
      expect(subject).to receive(:broadcast_event).with(not_found_error_properties, "")
      subject.on_message(di, props, body)
    end

    it "should broadcast an error and consume the message if the there is any other type of error" do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["500", "some string about something"])
      expect(channel).to receive(:ack).with(delivery_tag, false)
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
        :individual_id => individual_id,
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:individual_created_properties) { {
      :routing_key => "info.application.gluedb.individual_update_event_listener.individual_created",
      :headers => {
        :return_status => "200",
        :individual_id => individual_id, 
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:individual_change_set) {
      instance_double("::ChangeSets::IndividualChangeSet", :individual_exists? => false, :create_individual_resource => creation_result, :full_error_messages => full_error_messages)
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
    let(:new_individual_resource) {
      double(:to_s => "a body value for the resource")
    }

    let(:individual_change_set) {
      instance_double("::ChangeSets::IndividualChangeSet", :individual_exists? => true, :any_changes? => changed_value, :multiple_changes? => multiple_changes_result, :dob_changed? => dob_change_result, :full_error_messages => full_error_messages)
    }

    let(:individual_updated_properties) { {
      :routing_key => "info.application.gluedb.individual_update_event_listener.individual_updated",
      :headers => {
        :return_status => "200",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:individual_update_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.individual_updated",
      :headers => {
        :return_status => "422",
        :individual_id => individual_id, 
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:individual_dob_changed_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.individual_dob_changed",
      :headers => {
        :return_status => "501",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:individual_unchanged_properties) { {
      :routing_key => "info.application.gluedb.individual_update_event_listener.individual_updated",
      :headers => {
        :return_status => "304",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp.to_i
      }
    } }

    let(:multiple_changes_result) { false}
    let(:dob_change_result) { false}
    let(:full_error_messages) { ["a", "list of", "error messages"] }

    before :each do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["200", new_individual_resource])
      allow(ChangeSets::IndividualChangeSet).to receive(:new).with(new_individual_resource).and_return(individual_change_set)
    end

    describe "with no changes" do
      let(:changed_value) { false }
      it "should just consume the message" do
        expect(channel).to receive(:ack).with(delivery_tag, false)
        expect(subject).to receive(:broadcast_event).with(individual_unchanged_properties, "a body value for the resource")
        subject.on_message(di, props, body)
      end
    end

    describe "with a single change" do
      let(:multiple_changes_result) { false}
      let(:changed_value) { true }

      describe "and that change is to dob" do
        let(:dob_change_result) { true }
        it "should send the message to the error queue and consume the message" do
          expect(channel).to receive(:ack).with(delivery_tag, false)
          expect(subject).to receive(:broadcast_event).with(individual_dob_changed_properties, "a body value for the resource")
          subject.on_message(di, props, body)
        end
      end

      describe "and that change is not to dob" do
        let(:dob_change_result) { false }
        describe "with an invalid update" do
          it "should log an error and consume the message" do
            expect(channel).to receive(:ack).with(delivery_tag, false)
            expect(individual_change_set).to receive(:process_first_edi_change).and_return(false)
            expect(subject).to receive(:broadcast_event).with(individual_update_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
            subject.on_message(di, props, body)
          end
        end

        describe "with a valid update" do
          it "should process the first change and transmit edi" do
            expect(channel).to receive(:ack).with(delivery_tag, false)
            expect(individual_change_set).to receive(:process_first_edi_change).and_return(true)
            expect(subject).to receive(:broadcast_event).with(individual_updated_properties, "a body value for the resource")
            subject.on_message(di, props, body)
          end
        end
      end
    end

    describe "with multiple changes" do
      let(:multiple_changes_result) { true }
      let(:changed_value) { true }

      describe "with an invalid update" do
        it "should log an error and consume the message" do
          expect(channel).to receive(:ack).with(delivery_tag, false)
          expect(individual_change_set).to receive(:process_first_edi_change).and_return(false)
          expect(subject).to receive(:broadcast_event).with(individual_update_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
          subject.on_message(di, props, body)
        end
      end

      describe "with a valid update" do
        let(:individual_updated_properties) { {
            :routing_key => "info.application.gluedb.individual_update_event_listener.individual_updated_partially",
            :headers => {
                :return_status => "200",
                :individual_id => individual_id,
                :submitted_timestamp => timestamp.to_i
            }
        } }

        it "should process the first change and requeue" do
          expect(channel).to receive(:reject).with(delivery_tag, true)
          expect(individual_change_set).to receive(:process_first_edi_change).and_return(true)
          expect(subject).to receive(:broadcast_event).with(individual_updated_properties, "a body value for the resource")
          subject.on_message(di, props, body)
        end
      end
    end
  end
end
