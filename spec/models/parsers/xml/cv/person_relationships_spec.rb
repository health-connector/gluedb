require 'rails_helper'

describe Parsers::Xml::Cv::PersonRelationshipParser do
  before(:all) do
    xml_file = File.open(File.join(Rails.root, "spec", "data", "person_relationships.xml")).read
    @subject = Parsers::Xml::Cv::PersonRelationshipParser.parse(xml_file)
  end

  let(:subject_individual_id) {"urn:openhbx:hbx:dc0:dcas:individual#2004542"}

  let(:object_individual_id) {"urn:openhbx:hbx:dc0:dcas:individual#2004818"}

  let(:relationship_uri) {"urn:openhbx:terms:v1:individual_relationship#spouse"}

  it "should have the subject_individual_id " do
    expect(@subject.subject_individual_id).to eq(subject_individual_id)
  end

  it "should have the object_individual_id " do
    expect(@subject.object_individual_id).to eq(object_individual_id)
  end

  it "should have the relationship_uri " do
    expect(@subject.relationship_uri).to eq(relationship_uri)
  end
end