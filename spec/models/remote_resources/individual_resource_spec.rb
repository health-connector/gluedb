require "rails_helper"

describe RemoteResources::IndividualResource do
  let(:example_data) {
    o_file = File.open(File.join(Rails.root, "spec/data/remote_resources/individual.xml"))
    data = o_file.read
    o_file.close
    data
  }


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

    describe "for an existing resource" do
      let(:response_props) { 
        double(:headers => {
          :return_status => "200"
        })
      }

      let(:resource_response_body) {
        o_file = File.open(File.join(Rails.root, "spec/data/remote_resources/individual.xml"))
        data = o_file.read
        o_file.close
        data
      }

      before :each do
        allow(requestable).to receive(:request).with(request_properties, "", 15).and_return([nil, response_props, example_data]) 
      end

      it "should have a response code of 200" do
        rcode, body = RemoteResources::IndividualResource.retrieve(requestable, individual_id)
        expect(rcode.to_s).to eq "200"
      end

      it "should return the parsed payload" do
        rcode, returned_resource = RemoteResources::IndividualResource.retrieve(requestable, individual_id)
        expect(returned_resource.kind_of?(RemoteResources::IndividualResource)).to eq true
      end
    end
  end

  describe "given example data to parse" do
    subject { RemoteResources::IndividualResource.parse(example_data, :single => true) }

    it "should have the correct hbx_member_id" do
      expect(subject.hbx_member_id).to eq("18941339")
    end

    it "should have the correct names" do
      expect(subject.name_first).to eq "Sulis"
      expect(subject.name_last).to eq "Minerva"
      expect(subject.name_middle).to eq "J"
      expect(subject.name_pfx).to eq "Dr."
      expect(subject.name_sfx).to eq "of Bath"
    end

    it "should have the correct demographic information" do
      expect(subject.ssn).to eq "321470519"
      expect(subject.dob).to eq Date.new(1973, 7, 24)
      expect(subject.gender).to eq "female"
    end

    it "should have the correct addresses" do
       address = subject.addresses.first
       expect(address.address_kind).to eq "home"
       expect(address.address_line_1).to eq "2515 I Bath Street NW"
       expect(address.address_line_2).to eq "Apt. Whatever"
       expect(address.location_city_name).to eq "Washington"
       expect(address.location_state_code).to eq "DC"
       expect(address.postal_code).to eq "20037"
    end

    it "should have the correct emails" do
      email = subject.emails.first
      expect(email.email_kind).to eq "home"
      expect(email.email_address).to eq "sminerva@gmail.com"
    end

    it "should have the correct phones" do
      first_phone = subject.phones.first
      second_phone = subject.phones.last
      expect(first_phone.phone_kind).to eq "home"
      expect(first_phone.full_phone_number).to eq "5882300123"
      expect(first_phone.ignored?).to eq false
      expect(second_phone.ignored?).to eq true
    end
  end

  describe "when that record does not exist in the db" do
    let(:member_query) { double(:execute => nil) }
    subject { RemoteResources::IndividualResource.parse(example_data, :single => true) }

    it "should not exist" do
      allow(::Queries::PersonByHbxIdQuery).to receive(:new).with("18941339").and_return(member_query)
      expect(subject.exists?).to be false
    end
  end

  describe "when that record does exists in the db" do
    let(:member_query) { double(:execute => double) }
    subject { RemoteResources::IndividualResource.parse(example_data, :single => true) }

    it "should not exist" do
      allow(::Queries::PersonByHbxIdQuery).to receive(:new).with("18941339").and_return(member_query)
      expect(subject.exists?).to be true
    end
  end
end
