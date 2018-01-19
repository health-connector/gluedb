require "rails_helper"

describe Publishers::TradingPartnerEdi do
  let(:benefit_enrollment_transformer) { instance_double(EdiCodec::X12::BenefitEnrollment, :call => transformed_xml_document) }
  let(:transformed_xml_document) { double(:to_xml => x12_payload) }
  let(:amqp_connection) { double }
  let(:event_xml) { double }
  let(:enrollment_event_cv) { instance_double(::Openhbx::Cv2::EnrollmentEvent, :event => enrollment_event_event) }
  let(:enrollment_event_event) { instance_double(::Openhbx::Cv2::EnrollmentEventEvent, :body => enrollment_event_body) }
  let(:enrollment_event_body) { instance_double(::Openhbx::Cv2::EnrollmentEventBody, :publishable? => true, :transaction_id => "placeholder_transaction_id", :enrollment => enrollment_event_enrollment) }
  let(:enrollment_event_body) { instance_double(::Openhbx::Cv2::EnrollmentEventBody, :publishable? => true, :transaction_id => "placeholder_transaction_id", :enrollment => enrollment_event_enrollment) }
  let(:enrollment_event_enrollment) { instance_double(::Openhbx::Cv2::EnrollmentEvent) }
  let(:policy_cv) { instance_double(::Openhbx::Cv2::Policy) }
  let(:amqp_channel) { double(:default_exchange => default_exchange) }
  let(:default_exchange) { double }
  let(:x12_payload) { double }
  let(:updated_event_xml) { double }

  subject { ::Publishers::TradingPartnerEdi.new(amqp_connection, event_xml) }

  describe "#publish" do

    before :each do
      allow(subject).to receive(:enrollment_event_cv_for).with(event_xml).and_return(enrollment_event_cv)
      allow(subject).to receive(:update_transaction_id).with(event_xml, "generated_transaction_id").and_return(updated_event_xml)
      allow(subject).to receive(:new_transaction_id).and_return("generated_transaction_id")
      allow(subject).to receive(:is_initial?).with(x12_payload).and_return(false)
      allow(subject).to receive(:determine_market).with(enrollment_event_cv).and_return("shop")
      allow(subject).to receive(:find_carrier_abbreviation).with(enrollment_event_cv).and_return("GHMSI")
      allow(::EdiCodec::X12::BenefitEnrollment).to receive(:new).with(updated_event_xml).and_return(benefit_enrollment_transformer)
      allow(::Amqp::ConfirmedPublisher).to receive(:with_confirmed_channel).with(amqp_connection).and_yield(amqp_channel)
    end

    it "publishes with the correct generated file name" do
      expect(default_exchange).to receive(:publish).with(
        x12_payload,
        {
          :routing_key => "hbx.maintenance_messages",
          :headers => {
            "market" => "shop",
            "file_name" => "834_generated_transaction_id_GHMSI_C_M_S_1.xml"
          }
        }
      )
      subject.publish
    end
  end

end
