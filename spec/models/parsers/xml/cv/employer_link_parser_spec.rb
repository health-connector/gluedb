require 'rails_helper'
require 'pry'

describe Parsers::Xml::Cv::EnrollmentParser do
  before(:all) do
    @xml_path = File.join(Rails.root, 'spec', 'data', 'lib', 'enrollment.xml')
    @xml = File.read(@xml_path)
    policy_parser = Parsers::Xml::Cv::PolicyParser.parse(@xml)
    @employer_link = policy_parser[0].enrollment.shop_market.employer_link
  #  policy =  PolicyBuilder.new(policy_parser.first.to_hash).policy
  end


  let(:name){ "United States Senate" }

  let(:dba){ "USS" }

  let(:id) {"http://10.83.85.127/api/v1/employers/53e6731deb899a460302a120"}


  it 'returns the name' do
    binding.pry
    expect(@employer_link.name).to eq(name)
  end

  it 'returns the dba' do
    expect(@employer_link.dba).to eq(dba)
  end

  it 'returns the id' do
    expect(@employer_link.id).to eq(id)
  end

end