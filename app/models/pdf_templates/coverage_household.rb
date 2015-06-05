 module PdfTemplates
  class CoverageHousehold
    include Virtus.model

    attribute :primary, PdfTemplates::Enrollee
    attribute :spouse, PdfTemplates::Enrollee
    attribute :dependents, Array[PdfTemplates::Enrollee]
    attribute :policy_ids, Array[Integer]
    
  end
end