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

  let(:subject_individual_id) {"urn:openhbx:hbx:dc0:dcas:individual#2004542"}

  let(:object_individual_id) {"urn:openhbx:hbx:dc0:dcas:individual#2004818"}

  let(:relationship_uri) {"urn:openhbx:terms:v1:individual_relationship#spouse"}

  let(:applicant_id) {"urn:openhbx:hbx:dc0:resources:v1:dcas:individual#2004542"}

  let(:is_primary_applicant) {"true"}

  let(:sex) {"urn:openhbx:terms:v1:gender#female"}

  let(:ssn) {"171765423"}

  let(:birth_date) {"19890110"}

  it 'should return e_case_id' do
    expect(subject.e_case_id).to eql(e_case_id)
  end

  it 'should have 2 people' do
    expect(subject.applicants.length).to eql(2)
  end


  describe "the first applicant" do
    it 'should have the right applicants id)' do
      expect(subject.applicants.first.person.id).to eql(applicant_id)
    end

    it 'should have person name first' do
      expect(subject.applicants.first.person.name_first).to eql(individual1.name_first)
    end

    it 'should have person name full' do
      expect(subject.applicants.first.person.name_full).to eql(individual1.name_full)
    end

    it 'should have 1 person relationship with relationship_uri, subject_individual_id, object_individual_id' do
      expect(subject.applicants.first.person_relationships.size).to eq(1)
      expect(subject.applicants.first.person_relationships.first.subject_individual_id).to eq(subject_individual_id)
      expect(subject.applicants.first.person_relationships.first.relationship_uri).to eq(relationship_uri)
      expect(subject.applicants.first.person_relationships.first.object_individual_id).to eq(object_individual_id)
    end

    it 'should have 1 person demographics with ssn, sex, date of birth..' do
      expect(subject.applicants.first.person_demographics.sex).to eq(sex)
      expect(subject.applicants.first.person_demographics.ssn).to eq(ssn)
      expect(subject.applicants.first.person_demographics.birth_date).to eq(birth_date)
    end

    it "should return the primary_applicant_id" do
      expect(subject.applicants.first.is_primary_applicant).to eq(is_primary_applicant)
    end

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