require "rails_helper"

describe RemoteResources::IndividualResource do

  describe "given a requestable object and an individual id url" do
    let(:requestable) { double }
    let(:individual_id) { "an individual id" }
    let(:request_properties) {
      {
        :routing_key => "resource.individual",
        :headers => {
          :individual_id => individual_id
        }
      }
    }

    describe "when the remote resource does not respond" do
      before :each do
        allow(requestable).to receive(:request).with(request_properties, "", 15).and_raise(Timeout::Error)
      end
      it "should return a 503" do
        rcode, body = RemoteResources::IndividualResource.retrieve(requestable, individual_id)
        expect(rcode.to_s).to eq "503"
      end
    end

    describe "for an individual uri which does not exist" do
      let(:response_props) { 
        double(:headers => {
          :return_status => "404"
        })
      }

      before :each do
        allow(requestable).to receive(:request).with(request_properties, "", 15).and_return([nil, response_props, ""])
      end

      it "should return a 404" do
        rcode, body = RemoteResources::IndividualResource.retrieve(requestable, individual_id)
        expect(rcode.to_s).to eq "404"
      end
    end
  end
end
