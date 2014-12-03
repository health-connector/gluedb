require 'rails_helper'

describe Applicant do

  let(:p0) {Person.create!(name_first: "Dan", name_last: "Aurbach")}
  let(:p1) {Person.create!(name_first: "Patrick", name_last: "Carney")}
  let(:ag) {ApplicationGroup.create()}

  describe "indexes specified fields" do
  end

  describe "instantiates object." do
    it "sets and gets all basic model fields and embeds in parent class" do
      a = Applicant.new(person: p0,
        is_primary_applicant: true,
        is_consent_applicant: true,
        is_ia_eligible: true,
        is_medicaid_chip_eligible: true,
        is_active: true
        )

      a.application_group = ag

      expect(a.person.name_last).to eql(p0.name_last)
      expect(a.is_primary_applicant?).to eql(true)
      expect(a.is_consent_applicant?).to eql(true)
      expect(a.is_ia_eligible?).to eql(true)
      expect(a.is_medicaid_chip_eligible?).to eql(true)
      expect(a.is_active?).to eql(true)
    end
  end

  describe "performs validations" do
  end

end