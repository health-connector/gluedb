module PdfTemplates
  class MonthlyPremium
    include Virtus.model

    attribute :serial, Integer
    attribute :calender_month, String
    attribute :premium_amount, String
    attribute :premium_amount_slcsp, String
    attribute :monthly_aptc, String
  end
end