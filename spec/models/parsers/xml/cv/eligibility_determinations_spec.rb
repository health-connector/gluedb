require 'rails_helper'

describe Parsers::Xml::Cv::EligibilityDeterminationParser do

  before(:all) do
    xml_file = File.open(File.join(Rails.root, "spec", "data", "eligibility_determinations.xml")).read
    @subject = Parsers::Xml::Cv::EligibilityDeterminationParser.parse(xml_file)
  end

  let(:id) {"2063333"}

  let(:household_state) {"urn:openhbx:terms:v1:household_state#cs7"}

  let(:maximum_aptc) {"0"}

  let(:csr_percent) {"0.0"}

  let(:determination_date) {"20131204"}

  it 'should have an id' do
    expect(@subject.id).to eq(id)
  end

  it 'should have an household_state' do
    expect(@subject.household_state).to eq(household_state)
  end

  it 'should have an maximum_aptc' do
    expect(@subject.maximum_aptc).to eq(maximum_aptc)
  end

  it 'should have an csr_percent' do
    expect(@subject.csr_percent).to eq(csr_percent)
  end

  it 'should have an determination_date' do
    expect(@subject.determination_date).to eq(determination_date)
  end

  it 'should have 2 applicants' do
    expect(@subject.applicants.size).to eq(2)
  end

end