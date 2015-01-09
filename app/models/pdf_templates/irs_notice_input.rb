module PdfTemplates
  class IrsNoticeInput
    include Virtus.model

    attribute :policy_number, String
    attribute :policy_id, String
    attribute :issuer_name, String
    attribute :recipient_address, PdfTemplates::NoticeAddress
    attribute :recipient, PdfTemplates::Enrolee
    attribute :spouse, PdfTemplates::Enrolee
    attribute :covered_household, Array[PdfTemplates::Enrolee]
    attribute :monthly_premiums, Array[PdfTemplates::MonthlyPremium]
  end
end