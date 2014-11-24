require 'rails_helper'

describe Parsers::Xml::Cv::PersonParser do
  before(:all) do
    xml_file = File.open(File.join(Rails.root, "spec", "data", "person.xml")).read
    @subject = Parsers::Xml::Cv::PersonParser.parse(xml_file)
  end

  let(:name_last){ "Ramirez" }

  let(:name_first){ "vroom" }

  let(:name_full){ "vroom Ramirez" }

  let(:id) {"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004542"}


  it 'returns the name_last' do
    expect(@subject.name_last).to eq(name_last)
  end

  it 'returns the first name' do
    expect(@subject.name_first).to eq(name_first)
  end

  it 'returns the name_full' do
    expect(@subject.name_full).to eq(name_full)
  end

  it 'returns the id' do
    expect(@subject.id).to eq(id)
    end

end