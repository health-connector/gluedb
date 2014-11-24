require 'rails_helper'

describe Parsers::Xml::Cv::ApplicantParser do

  before(:all) do
    xml_file = File.open(File.join(Rails.root, "spec", "data", "applicant.xml")).read
    @subject = Parsers::Xml::Cv::ApplicantParser.parse(xml_file)
  end

  let(:id){"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004542"}

  let(:name_first) {"vroom"}

  it 'should have the id' do
      expect(@subject.id).to eq(id)
  end

  it 'should have a person object' do
    expect(@subject.person.nil?).to eq(false)
    expect(@subject.person.name_first).to eq(name_first)
  end

  it 'should have 1 person relationship' do
    expect(@subject.person_relationships.size).to eq(1)
  end

  it 'should have 1 person relationship' do
    puts "#{@subject.is_primary_applicant}"
    expect(@subject.is_primary_applicant).to eq("true")
  end

end