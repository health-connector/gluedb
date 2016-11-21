require "rails_helper"

describe Handlers::TransmitEdiForEvent do
  let(:enrollment_group_id) { "2938749827349723974" }
  let(:pre_amt_tot) { "290.13" }
  let(:tot_res_amt) { "123.13" }
  let(:tot_emp_res_amt) { "234.30" }
  let(:transaction_id) { "123455463456345634563456" }
  let(:enrollment_event_cv) { instance_double(Openhbx::Cv2::EnrollmentEvent, event: enrollment_event_event) }
  let(:enrollment_event_event) { instance_double(Openhbx::Cv2::EnrollmentEventEvent, body: enrollment_event_body, event_name: event_type) }
  let(:enrollment_event_body) { instance_double(Openhbx::Cv2::EnrollmentEventBody, enrollment: enrollment, transaction_id: transaction_id, publishable?: publish_event_to_trading_partners) }
  let(:enrollment) { instance_double(Openhbx::Cv2::Enrollment, policy: policy_cv) }
  let(:policy_cv) { instance_double(Openhbx::Cv2::Policy, :policy_enrollment => enrollment_element) }
  let(:shop_enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollmentShopMarket) }
  let(:individual_enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollmentIndividualMarket) }
  let(:hios_id) { "l2k3j4kljfkdscd-01" }
  let(:plan_link) { instance_double(Openhbx::Cv2::PlanLink, :id => "urn:openhbx:hios##{hios_id}", :active_year => "2016") }
  let(:raw_event_xml) { "Some event xml" }
  let(:nokogiri_result_slug) { double(:to_xml => transformation_result_xml) }
  let(:transform_slug) { instance_double(EdiCodec::X12::BenefitEnrollment, :call => nokogiri_result_slug) }
  let(:transformation_result_xml) { double }
  let(:channel_slug) { double(:default_exchange => exchange_slug) }
  let(:exchange_slug) { double }
  let(:plan) { instance_double(Plan, carrier: carrier) }
  let(:carrier) { instance_double(Carrier, abbrev: "GhmSi") }
  let(:publish_event_to_trading_partners) { true }

  let(:app) do
    Proc.new do |context|
      context
    end
  end

  let(:amqp_connection) { double }

  let(:interaction_context) {
    OpenStruct.new({
      :raw_event_xml => raw_event_xml,
      :amqp_connection => amqp_connection
    })
  }

  let(:handler) {  Handlers::TransmitEdiForEvent.new(app) }

  before :each do
    allow(Openhbx::Cv2::EnrollmentEvent).to receive(:parse).with(raw_event_xml, :single => true).and_return(enrollment_event_cv)
    allow(EdiCodec::X12::BenefitEnrollment).to receive(:new).with(raw_event_xml).and_return(transform_slug)
    allow(::Amqp::ConfirmedPublisher).to receive(:with_confirmed_channel).with(amqp_connection).and_yield(channel_slug)
    allow(Plan).to receive(:where).with(:hios_plan_id => hios_id, :year => 2016).and_return([plan])
  end

  describe "given an initial enrollment for IVL" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :individual_market => :individual_enrollment_element, :shop_market => nil, :plan => plan_link) }
    let(:event_type) { "urn:openhbx:terms:v1:enrollment#initial" }

    let(:expected_properties) do
      { 
        :routing_key => "hbx.enrollment_messages",
        :headers => {
          "market" => "individual",
          "file_name" => "834_#{transaction_id}_GHMSI_C_E_I_1.xml"
        }
      }
    end

    it "should transmit a correctly named file, in the right market" do
      expect(exchange_slug).to receive(:publish).with(transformation_result_xml, expected_properties)
      handler.call(interaction_context)  
    end
  end

  describe "given a maintenance enrollment for IVL" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :individual_market => :individual_enrollment_element, :shop_market => nil, :plan => plan_link) }
    let(:event_type) { "urn:openhbx:terms:v1:enrollment#change_member_add" }

    let(:expected_properties) do
      { 
        :routing_key => "hbx.maintenance_messages",
        :headers => {
          "market" => "individual",
          "file_name" => "834_#{transaction_id}_GHMSI_C_M_I_1.xml"
        }
      }
    end

    it "should transmit a correctly named file, in the right market" do
      expect(exchange_slug).to receive(:publish).with(transformation_result_xml, expected_properties)
      handler.call(interaction_context)  
    end
  end

  describe "given an initial enrollment for SHOP" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :individual_market => nil, :shop_market => shop_enrollment_element, :plan => plan_link) }
    let(:event_type) { "urn:openhbx:terms:v1:enrollment#initial" }

    let(:expected_properties) do
      { 
        :routing_key => "hbx.enrollment_messages",
        :headers => {
          "market" => "shop",
          "file_name" => "834_#{transaction_id}_GHMSI_C_E_S_1.xml"
        }
      }
    end

    it "should transmit a correctly named file, in the right market" do
      expect(exchange_slug).to receive(:publish).with(transformation_result_xml, expected_properties)
      handler.call(interaction_context)  
    end
  end

  describe "given a maintenance enrollment for SHOP" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :individual_market => nil, :shop_market => shop_enrollment_element, :plan => plan_link) }
    let(:event_type) { "urn:openhbx:terms:v1:enrollment#change_product" }

    let(:expected_properties) do
      { 
        :routing_key => "hbx.maintenance_messages",
        :headers => {
          "market" => "shop",
          "file_name" => "834_#{transaction_id}_GHMSI_C_M_S_1.xml"
        }
      }
    end

    it "should transmit a correctly named file, in the right market" do
      expect(exchange_slug).to receive(:publish).with(transformation_result_xml, expected_properties)
      handler.call(interaction_context)  
    end
  end

  describe "given an event which isn't publishable" do
    let(:enrollment_element) { instance_double(Openhbx::Cv2::PolicyEnrollment, :individual_market => nil, :shop_market => shop_enrollment_element, :plan => plan_link) }
    let(:event_type) { "urn:openhbx:terms:v1:enrollment#change_product" }
    let(:publish_event_to_trading_partners) { false }

    it "does not transmit" do
      expect(exchange_slug).not_to receive(:publish)
      handler.call(interaction_context)
    end
  end
end
