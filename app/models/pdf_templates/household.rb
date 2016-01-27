module PdfTemplates
  class Household
    include Virtus.model

    attribute :effective_start_date
    attribute :effective_end_date
    attribute :has_aptc, Boolean, :default => false

    attribute :tax_households, Array[PdfTemplates::TaxHousehold]
    attribute :coverage_households, Array[PdfTemplates::CoverageHousehold]


    def irs_households
      has_aptc ? tax_households : coverage_households
    end
  end
end