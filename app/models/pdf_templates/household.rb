module PdfTemplates
  class Household
    include Virtus.model

    attribute :effective_start_date, DateTime
    attribute :effective_end_date, DateTime

    attribute :primary, PdfTemplates::Enrollee
    attribute :spouse, PdfTemplates::Enrollee
    attribute :dependents, Array[PdfTemplates::Enrollee]
    attribute :monthly_enrollments, Hash[Integer => PdfTemplates::IrsPolicy]
  end
end