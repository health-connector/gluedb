require "rails_helper"

shared_examples_for "a phone partial" do
  it "has phone" do
    expected_node = subject.at_xpath("//phone/type")
    expect(expected_node.content).to eq "urn:openhbx:terms:v1:phone_type##{phone_type}"
  end

  it "has phone number" do
    expected_node = subject.at_xpath("//phone/full_phone_number")
    expect(expected_node.content).to eq phone_number
  end
end

describe "people/_phone.xml" do
  let(:phone_type) { "home" }
  let(:phone_number) {"7032299943"}
  let(:primary) { "1" }
  let(:render_result) {
                        render :partial => "people/phone", :formats => [:xml], :object => phone
                        rendered
                      }

  subject{
    Nokogiri::XML(render_result)
  }

  describe "Given:
                - Have an phone number and phone type" do

    let(:phone) { instance_double(Phone, {
                                            :phone_type => phone_type,
                                            :phone_number => phone_number,
                                            :primary => nil,
                                            :full_phone_number => nil
                                        }) }

    it_should_behave_like "a phone partial"
    it "has no preferrence" do
      expected_node = subject.at_xpath("//phone/is_preferred")
      expect(expected_node.content).to eq "false"
    end
  end

  describe "Given:
                - Have primary" do
    let(:phone) { instance_double(Phone, {
                                          :phone_type => phone_type,
                                          :phone_number => phone_number,
                                          :primary => primary,
                                          :full_phone_number => nil
                                      }) }

    it_should_behave_like "a phone partial"
    it "has preferrence" do
      expected_node = subject.at_xpath("//phone/is_preferred")
      expect(expected_node.content).to eq primary
    end
  end
end