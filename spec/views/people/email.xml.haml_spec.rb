require "rails_helper"

shared_examples_for "a email partial" do
  it "has email_type" do
    expected_node = subject.at_xpath("//email/type")
    expect(expected_node.content).to eq "urn:openhbx:terms:v1:email_type##{email_type}"
  end

  it "has email_address" do
    expected_node = subject.at_xpath("//email/email_address")
    expect(expected_node.content).to eq email_address
  end
end

describe "people/_email.xml" do
  let(:email_type){"home"}
  let(:email_address){"Some email address"}
  let(:render_result){
    render :partial => "people/email", :formats => [:xml], :object=> email
    rendered
  }
  subject{
    Nokogiri::XML(render_result)
  }

  describe "Given:
                - Have an email type and an email address" do
    let(:email) { instance_double(Email, {
                                            :email_type => email_type,
                                            :email_address => email_address
                                        }) }
    it_should_behave_like "a email partial"
  end
end
