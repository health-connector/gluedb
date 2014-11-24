require 'rails_helper'

describe Parsers::Xml::Cv::EligibilityDeterminationParser do

  before(:all) do
    xml_file = File.open(File.join(Rails.root, "spec", "data", "eligibility_determinations.xml")).read
    @subject = Parsers::Xml::Cv::EligibilityDeterminationParser.parse(xml_file)
  end

  let(:id) {"2063333"}

  it 'should have an id' do
    expect(@subject.first.id).to eq(id)
  end
end