 module PdfTemplates
  class TaxHousehold
    include Virtus.model

    attribute :tax_household_coverages, Array[PdfTemplates::TaxHouseholdCoverage]

    def coverages
      tax_household_coverages.select {|c| !c.policy_ids.empty? }
    end

    def policy_ids
      coverages.inject([]) {|pols, coverage| pols += coverage.policy_ids }
    end
  end
end