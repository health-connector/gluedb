require "rails_helper"

describe Handlers::EnrollmentEventXmlHelper do
  subject { Class.new { extend Handlers::EnrollmentEventXmlHelper } }

  describe "#extract_subscriber" do
    let(:subscriber) { instance_double(Enrollee) }
    let(:dependent) { instance_double(Enrollee) }

    let(:policy_cv) { double(:enrollees => [subscriber, dependent]) }

    before do
      allow(subscriber).to receive(:subscriber?).and_return(true)
      allow(dependent).to receive(:subscriber?).and_return(false)
    end
    it "returns the subscriber only" do
      expect(subject.extract_subscriber(policy_cv)).to eq(subscriber)
    end
  end

  describe "#extract_member_id" do
    let(:enrollee) { double('Enrollee', :member => member, :value => self) }
    let(:member) { instance_double(Member, id: "ABC#54")}

    it "returns the numeric id" do
      expect(subject.extract_member_id(enrollee)).to eq("54")
    end
  end

  describe "#extract_enrollee_start" do
    let(:benefit) { double(:begin_date => "20170101") }
    let(:enrollee) { double(:benefit => benefit)}
    it "returns the parsed date" do
      expect(subject.extract_enrollee_start(enrollee)).to eq(Date.new(2017,1,1))
    end
  end

  describe "#extract_enrollee_end" do
    let(:benefit) { double(:end_date => "20170101") }
    let(:enrollee) { double(:benefit => benefit)}
    it "returns the parsed date" do
      expect(subject.extract_enrollee_end(enrollee)).to eq(Date.new(2017,1,1))
    end
  end
end
