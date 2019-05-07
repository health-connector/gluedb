require 'spec_helper'
require 'rails_helper'
require_relative '../../script/queries/policies_missing_transmissions.rb'

describe PoliciesMissingTransmissions do

  let!(:policies) { FactoryGirl.create_list(:policy, 20) }

  subject { PoliciesMissingTransmissions.new }

  it "should process policies missing transmissions and create a csv report" do
    subject.process
    csv_filename = "policies_without_transmissions_#{subject.timestamp}.csv"
    expect(File.exist?(csv_filename)).to eq(true)
    fields = ['Created At', 'Enrollment Group ID', 'Carrier', 'Employer', 'Subscriber Name', 'Subscriber HBX ID']
    CSV.read(csv_filename).each do |row|
      expect(CSV.read(csv_filename)[0]).to eq fields
    end
    # Delete and remove from spec
    File.delete(csv_filename)
  end
end
