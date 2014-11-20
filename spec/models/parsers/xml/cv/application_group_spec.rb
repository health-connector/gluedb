require 'rails_helper'

describe Parsers::Xml::Cv::ApplicationGroup do

  let(:application_group) {
    f = File.open(File.join(Rails.root, "spec", "data", "application_group.xml"))
    f.read
  }

  subject {
    Parsers::Xml::Cv::ApplicationGroup.parse(application_group, :single => true)
  }

  let(:individual1) {double(name_last:"Ramirez", name_first:"vroom", name_full:"vroom Ramirez", id:"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004542")}

  let(:individual2) {double(name_last:"Pandu De Leon", name_first:"Vicky", name_full:"Vicky De Leon", id:"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004818")}

  let(:individuals) {[individual1, individual2]}

  let(:primary_applicant_id) {"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004542"}

  let(:submitted_date) {"20131204"}

  let(:e_case_id) {"urn:openhbx:hbx:dc0:resources:v1:curam:integrated_case#2063332"}

  it 'should return e_case_id' do
    expect(subject.e_case_id).to eql(e_case_id)
  end

  it 'should have 2 people' do
    expect(subject.people.length).to eql(2)
  end

  it 'should have the right applicants(mathing name attribute)' do
    expect(subject.people.first.name_first).to eql(individual1.name_first)
  end

  describe "the first applicant" do

  end

  describe "the second applicant" do

  end

  it "should return the primary_applicant_id" do
    expect(subject.primary_applicant_id).to eq(primary_applicant_id)
  end

  it "should return the submitted_date" do
    expect(subject.submitted_date).to eq(submitted_date)
  end

end