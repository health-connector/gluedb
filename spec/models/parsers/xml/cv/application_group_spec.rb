require 'rails_helper'

describe Parsers::Xml::Cv::ApplicationGroup do

  let(:application_group) {
    f = File.open(File.join(Rails.root, "spec", "data", "application_group.xml"))
    Nokogiri::XML(f).root
  }

  subject {
    Parsers::Xml::Cv::ApplicationGroup.new(application_group)
  }

  let(:individual) {double}

  let(:individuals) {[individual, individual]}

  let(:primary_applicant_id) {"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004542"}

  let(:coverage_renewal_year) {""}

  it 'should be a valid xml' do
    expect(subject.class).to eq(Parsers::Xml::Cv::ApplicationGroup)
  end

  it 'should return the list of individuals' do

    puts subject.individuals.inspect
    expect(subject.individuals).to eq(individuals)
  end

  it "should return the primary_applicant_id" do
    expect(subject.primary_applicant_id).to eq(primary_applicant_id)
  end

  it "should return the primary_applicant_id" do
    expect(subject.primary_applicant_id).to eq(primary_applicant_id)
  end

  it "should return the submitted_date" do
    expect(subject.submitted_date).to eq(submitted_date)
  end

  it "should return the coverage_renewal_year" do
    expect(subject.coverage_renewal_year).to eq(coverage_renewal_year)
  end
end