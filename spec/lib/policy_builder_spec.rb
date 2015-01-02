require 'rails_helper'

describe PolicyBuilder do

  before(:all) do
    @xml_path = File.join(Rails.root, 'spec', 'data', 'lib', 'enrollment.xml')
    @xml = File.read(@xml_path)
    policy_parser = Parsers::Xml::Cv::PolicyParser.parse(@xml)
    @policy = PolicyBuilder.new(policy_parser.first.to_hash).policy
  end

  it "constructs the object" do
    expect(@policy.nil?).to eq(false)
  end

  it "should construct a valid object" do
    puts @policy.class
    @policy.valid?
    puts @policy.errors.full_messages.inspect

    expect(@policy.valid?).to eq(true)
  end
end