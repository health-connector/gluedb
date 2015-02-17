module PdfTemplates
  class IrsGroup
    include Virtus.model

    attribute :identification_num, String
    attribute :households, Array[PdfTemplates::Household]
  end
end