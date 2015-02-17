module PdfTemplates
  class IrsGroup
    include Virtus.model

    attribute :identification_num, String
    attribute :tax_households, Array[PdfTemplates::TaxHousehold]
    attribute :associated_policies, Array[PdfTemplates::IrsNoticeInput]

    def policy_ids
      tax_households.inject([]) { |pols, th| pols += th.policy_ids }.flatten.uniq
    end
  end
end