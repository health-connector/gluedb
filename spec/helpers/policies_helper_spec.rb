require "#{Rails.root}/app/helpers/policies_helper"

RSpec.describe PoliciesHelper, :type => :helper do

  describe "show_1095A_document_button?" do
    let(:policy) { FactoryGirl.create(:policy) }

    context "2017 policy" do
      let(:subscriber) { FactoryGirl.create(:enrollee, :coverage_start => Date.new(2017,01,01)) }
      before do
        allow(policy).to receive(:subscriber).and_return(subscriber)
      end

      it "returns false" do
        expect(subject.show_1095A_document_button?).to be_falsey
      end
    end

    context "2016 policy" do
      let(:subscriber) { FactoryGirl.create(:enrollee, :coverage_start => Date.new(2016,01,01)) }
      before do
        allow(policy).to receive(:subscriber).and_return(subscriber)
      end

      it "returns false" do
        expect(subject.show_1095A_document_button?).to be_truthy
      end
    end
  end
end