require "rails_helper"

describe NewEnrollmentRequest do


  let(:xml) { File.open(file_path).read }

  subject { NewEnrollmentRequest.from_xml(xml) }

  describe "with file n4601383594475126784.xml" do

    let(:file_path) { File.join(Rails.root, "spec/data/request_models/new_enrollment_request/n4601383594475126784.xml") }

    it "should have a single policy" do
      expect(subject[:policies].length).to eql 1
    end

    it "should have a single individual" do
      expect(subject[:individuals].length).to eql 1
    end
  end

end
