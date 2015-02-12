module PdfTemplates
  class IrsPolicy
    include Virtus.model

    attribute :qhp_policy_id, String
    attribute :qhp_id, String
    attribute :issuer_name, String
    attribute :qhp_issuer_ein, String
    attribute :coverage_start, String
    attribute :coverage_end, String
    attribute :covered_household, Array[PdfTemplates::Member]
    attribute :monthly_premiums, Array[PdfTemplates::MonthlyPremium]
    attribute :has_aptc, Boolean, :default => false
    attribute :yearly_premium, PdfTemplates::YearlyPremium
  end
end