require "rails_helper"

describe ::RemoteResources::EnrollmentEventResource, "with an enrollment event cv" do
  XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

  describe "instructed to set it's publishible value" do

    let(:resource_xml) do
      <<-XMLCODE
      <enrollment_event xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://openhbx.org/api/terms/1.0">
        <enrollment_event_body>
          <is_trading_partner_publishable>SOME GARBAGE VALUE</is_trading_partner_publishable>
        </enrollment_event_body>
      </enrollment_event>
      XMLCODE
    end

    subject { ::RemoteResources::EnrollmentEventResource.new(resource_xml) }

    before :each do
      @event_xml = subject.set_trading_partner_publishable(publishable_value)
    end

    describe "as not publishable" do
      let(:publishable_value) { "false" }

      it "has is_trading_partner_publishable as false in the xml" do
        xml_doc = Nokogiri::XML(@event_xml)
        xml_document_value = xml_doc.xpath("//cv:enrollment_event_body/cv:is_trading_partner_publishable", XML_NS).first.content
        expect(xml_document_value).to eq "false"
      end

      it "has is_trading_partner_publishable as false in the event_body" do
        xml_doc = Nokogiri::XML(subject.body)
        xml_document_value = xml_doc.xpath("//cv:enrollment_event_body/cv:is_trading_partner_publishable", XML_NS).first.content
        expect(xml_document_value).to eq "false"
      end
    end

    describe "as publishable" do
      let(:publishable_value) { "true" }

      it "has is_trading_partner_publishable as true in the xml" do
        xml_doc = Nokogiri::XML(@event_xml)
        xml_document_value = xml_doc.xpath("//cv:enrollment_event_body/cv:is_trading_partner_publishable", XML_NS).first.content
        expect(xml_document_value).to eq "true"
      end

      it "has is_trading_partner_publishable as false in the event_body" do
        xml_doc = Nokogiri::XML(subject.body)
        xml_document_value = xml_doc.xpath("//cv:enrollment_event_body/cv:is_trading_partner_publishable", XML_NS).first.content
        expect(xml_document_value).to eq "true"
      end
    end

  end
end
