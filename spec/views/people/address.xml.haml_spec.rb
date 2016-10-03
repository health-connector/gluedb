require "rails_helper"

shared_examples_for "an address partial" do
    it "has address_line_1" do
      expected_node = subject.at_xpath("//address/address_line_1")
      expect(expected_node.content).to eq address_line_1
    end

    it "has city" do
      expected_node = subject.at_xpath("//address/location_city_name")
      expect(expected_node.content).to eq city
    end
end

describe "people/_address.xml" do
  let(:address_line_1) { "Some first address on a street" }
  let(:city) { "City" }
  let(:render_result) {
    render :partial => "people/address", :formats => [:xml], :object => address
    rendered
  }

  subject {
    Nokogiri::XML(render_result)
  }

  describe "Given:
              - An address_1,
              - NO address_2" do
    let(:address) { instance_double(Address, {
      :address_type => "home",
      :address_1 => address_line_1,
      :address_2 => nil,
      :address_3 => nil,
      :city => city,
      :state => nil,
      :zip => nil,
      :zip_extension => nil
    }) }

    it_should_behave_like "an address partial"

    it "has no address_line_2" do
      expected_node = subject.at_xpath("//address/address_line_2")
      expect(expected_node).to eq nil
    end
  end

  describe "Given:
              - An address_1,
              - An address_2" do
    let(:address_line_2) { "Some apartment number" }
    let(:address) { instance_double(Address, {
      :address_type => "home",
      :address_1 => address_line_1,
      :address_2 => address_line_2,
      :address_3 => nil,
      :city => city,
      :state => nil,
      :zip => nil,
      :zip_extension => nil
    }) }

    it_should_behave_like "an address partial"

    it "has address_line_2" do
      expected_node = subject.at_xpath("//address/address_line_2")
      expect(expected_node.content).to eq address_line_2
    end
  end

end
