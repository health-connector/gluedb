module PdfTemplates
  class YearlyPremium
    include Virtus.model

    attribute :premium_amount, String
    attribute :slcsp_premium_amount, String
    attribute :aptc_amount, String
  end
end