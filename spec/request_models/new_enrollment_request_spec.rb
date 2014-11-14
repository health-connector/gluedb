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

    describe "then the single policy inside" do
      let(:policy) { subject[:policies].first }

      it "should have the correct enrollment group id" do
        expect(policy[:enrollment_group_id]).to eql("-4601383594475126784")
      end

      it "should have the correct hios_id" do
        expect(policy[:hios_id]).to eql("86052DC0410002-01")
      end

      it "should have the correct plan_year" do
        expect(policy[:hios_id]).to eql("2014")
      end
    end
  end

end
