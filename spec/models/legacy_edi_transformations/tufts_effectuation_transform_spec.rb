require "rails_helper"

describe LegacyEdiTransformations::TuftsEffectuationTransform do

  let(:csv_row) { double }

  subject { LegacyEdiTransformations::TuftsEffectuationTransform.new }

  it "does nothing for now" do
    expect(subject.apply(csv_row)).to eq csv_row
  end

end
