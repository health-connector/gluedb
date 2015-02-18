module PdfTemplates
  class IrsGroup
    include Virtus.model

    attribute :identification_num, String
    attribute :tax_households, Array[PdfTemplates::TaxHousehold]
    attribute :insurance_policies, Array[PdfTemplates::IrsNoticeInput]

    def policy_ids
      tax_households.inject([]) { |pols, th| pols += th.policy_ids }.flatten.uniq
    end

    def policies_for_ids(policy_ids)
      insurance_policies.select{|x| policy_ids.include?(x.policy_id.to_i)}
    end
  end
end