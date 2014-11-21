require 'rails_helper'

describe Parsers::Xml::Cv::ApplicantParser do

  before(:all) do
    xml_file = File.open(File.join(Rails.root, "spec", "data", "applicant.xml")).read
    @subject = Parsers::Xml::Cv::ApplicantParser.parse(xml_file)
  end

  let(:id){"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004542"}

  it 'should have the id' do
      expect(@subject.id).to eq(id)
  end
end