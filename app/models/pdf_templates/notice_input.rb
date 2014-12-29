module PdfTemplates
  class NoticeInput
    include Virtus.model

    attribute :primary_name, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress

    attribute :covered_individuals, Array[String]

    attribute :health_plan_name, String
    attribute :dental_plan_name, String
    attribute :health_premium, String
    attribute :health_aptc, String
    attribute :health_responsible_amt, String
    attribute :dental_premium, String
    attribute :dental_aptc, String
    attribute :dental_responsible_amt, String
    attribute :notice_date, Date
  end
end
