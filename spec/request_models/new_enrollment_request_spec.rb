require "rails_helper"

describe NewEnrollmentRequest do

  let(:file_path) { File.join(Rails.root, "spec/data/request_models/new_enrollment_request/n4601383594475126784.xml") }

  let(:xml) { File.open(file_path).read }

  subject { NewEnrollmentRequest.from_xml(xml) }

  it "should run" do
    expect(subject).not_to be_nil
  end

end
