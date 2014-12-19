module PdfTemplates
  class NoticeInput
    include Virtus.model

    attribute :primary_name, String

    attribute :covered_individuals, Array[String]

    attribute :health_premium, String
    attribute :dental_premium, String
  end
end
