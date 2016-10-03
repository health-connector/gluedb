require "rails_helper"


# %person_surname= person_name.name_last
# %person_given_name= person_name.name_first
# - if !person_name.name_middle.blank?
#     %person_middle_name= person_name.name_middle
#     - if !person_name.name_pfx.blank?
#         %person_name_prefix_text= person_name.name_pfx
#         - if !person_name.name_sfx.blank?
#             %person_name_suffix_text= person_name.name_sfx

shared_examples_for "a person name partial" do
  it "has name_last" do
    expected_node = subject.at_xpath("//person_name/person_surname")
    expect(expected_node.content).to eq name_last
  end
  it "has name_first" do
    expected_node = subject.at_xpath("//person_name/person_given_name")
    expect(expected_node.content).to eq name_first
  end
end

describe "people/_person_name.xml" do
    let(:name_last){"Last name"}
    let(:name_first){"First name"}
    let(:render_result){
      render :partial => "people/person_name", :formats => [:xml], :object=> person_name
      rendered
    }
    subject{
      Nokogiri::XML(render_result)
    }

    describe "Given:
                - NO name_middle" do
      let(:person_name) { instance_double(Person, {
          :name_first => name_first,
          :name_last => name_last,
          :name_pfx => nil,
          :name_sfx => nil,
          :name_middle => nil
      }) }
      it_should_behave_like "a person name partial"
      it "has no name_middle" do
        expected_node = subject.at_xpath("//person_name/person_middle_name")
        expect(expected_node).to eq nil
      end
    end

    describe "Given:
              - An name_middle" do
    let(:name_middle) { "Some middle name" }
    let(:person_name) { instance_double(Person, {
        :name_first => name_first,
        :name_last => name_last,
        :name_pfx => nil,
        :name_sfx => nil,
        :name_middle => name_middle
    }) }
    it_should_behave_like "a person name partial"
    it "has name_middle" do
      expected_node = subject.at_xpath("//person_name/person_middle_name")
      expect(expected_node.content).to eq name_middle
    end
    end

    describe "Given:
                - NO name_pfx" do
      let(:person_name) { instance_double(Person, {
          :name_first => name_first,
          :name_last => name_last,
          :name_pfx => nil,
          :name_sfx => nil,
          :name_middle => nil
      }) }
      it_should_behave_like "a person name partial"
      it "has no name_pfx" do
        expected_node = subject.at_xpath("//person_name/person_name_prefix_text")
        expect(expected_node).to eq nil
      end
    end

    describe "Given:
              - An name_pfx" do
      let(:name_pfx) { "Some name_pfx" }
      let(:person_name) { instance_double(Person, {
          :name_first => name_first,
          :name_last => name_last,
          :name_pfx => name_pfx,
          :name_sfx => nil,
          :name_middle => nil
      }) }
      it_should_behave_like "a person name partial"
      it "has name_pfx" do
        expected_node = subject.at_xpath("//person_name/person_name_prefix_text")
        expect(expected_node.content).to eq name_pfx
      end
    end

end
# describe "people/_address.xml" do
#
#

#
#   describe "Given:
#               - An address_2" do
#     let(:address_line_2) { "Some apartment number" }
#     let(:address) { instance_double(Address, {
#         :address_type => "home",
#         :address_1 => address_line_1,
#         :address_2 => address_line_2,
#         :address_3 => nil,
#         :city => city,
#         :state => state,
#         :zip => zip,
#         :zip_extension => nil
#     }) }
#
#     it_should_behave_like "an address partial"
#
#     it "has address_line_2" do
#       expected_node = subject.at_xpath("//address/address_line_2")
#       expect(expected_node.content).to eq address_line_2
#     end
#   end
#
#   describe "Given:
#               - NO address_3" do
#     let(:address) { instance_double(Address, {
#         :address_type => "home",
#         :address_1 => address_line_1,
#         :address_2 => nil,
#         :address_3 => nil,
#         :city => city,
#         :state => state,
#         :zip => zip,
#         :zip_extension => nil
#     }) }
#
#     it_should_behave_like "an address partial"
#
#     it "has no address_line_3" do
#       expected_node = subject.at_xpath("//address/address_line_3")
#       expect(expected_node).to eq nil
#     end
#   end
#
#   describe "Given:
#               - An address_3" do
#     let(:address_line_3) { "Some apartment number" }
#     let(:address) { instance_double(Address, {
#         :address_type => "home",
#         :address_1 => address_line_1,
#         :address_2 => nil,
#         :address_3 => address_line_3,
#         :city => city,
#         :state => state,
#         :zip => zip,
#         :zip_extension => nil
#     }) }
#
#     it_should_behave_like "an address partial"
#
#     it "has address_line_2" do
#       expected_node = subject.at_xpath("//address/address_line_3")
#       expect(expected_node.content).to eq address_line_3
#     end
#   end
#
#   describe "Given:
#               - NO zip extension" do
#     let(:address) { instance_double(Address, {
#         :address_type => "home",
#         :address_1 => address_line_1,
#         :address_2 => nil,
#         :address_3 => nil,
#         :city => city,
#         :state => state,
#         :zip => zip,
#         :zip_extension => nil
#     }) }
#
#     it_should_behave_like "an address partial"
#
#     it "has no zip extension" do
#       expected_node = subject.at_xpath("//address/location_postal_extension_code")
#       expect(expected_node).to eq nil
#     end
#   end
#
#   describe "Given:
#               - An zip extension" do
#     let(:zip_extension) { "Some zip extension" }
#     let(:address) { instance_double(Address, {
#         :address_type => "home",
#         :address_1 => address_line_1,
#         :address_2 => nil,
#         :address_3 => nil,
#         :city => city,
#         :state => state,
#         :zip => zip,
#         :zip_extension => zip_extension
#     }) }
#
#     it_should_behave_like "an address partial"
#
#     it "has zip_extension" do
#       expected_node = subject.at_xpath("//address/location_postal_extension_code")
#       expect(expected_node.content).to eq zip_extension
#     end
#   end
#
# end
