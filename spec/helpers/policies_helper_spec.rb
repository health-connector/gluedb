require 'rails_helper'

RSpec.describe PoliciesHelper, :type => :helper do

  describe "show_1095A_document_button?" do
    let(:policy) { FactoryGirl.create(:policy) }

    context "current year policy" do
      let(:subscriber) { FactoryGirl.build(:enrollee, :coverage_start => Date.new(Date.today.year,01,01)) }
      before do
        allow(policy).to receive(:subscriber).and_return(subscriber)
      end

      it "returns false" do
        expect(helper.show_1095A_document_button?(policy)).to be_falsey
      end
    end

    context "previous year policy" do
      let(:subscriber) { FactoryGirl.build(:enrollee, :coverage_start => Date.new(Date.today.year - 1 ,01,01)) }
      before do
        allow(policy).to receive(:subscriber).and_return(subscriber)
      end

      it "returns false" do
        expect(helper.show_1095A_document_button?(policy)).to be_truthy
      end
    end
  end

  describe "disable_radio_button?" do

    context "canceled policy" do
      let(:policy) { FactoryGirl.create(:policy, aasm_state: 'canceled') }

      it "should return true" do
        expect(helper.disable_radio_button?(policy)).to be_truthy
      end
    end

    context "canceled policy" do
      let(:policy) { FactoryGirl.create(:policy, aasm_state: 'submitted') }

      it "should return false" do
        expect(helper.disable_radio_button?(policy)).to be_falsey
      end
    end
  end
end
