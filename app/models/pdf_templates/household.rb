module PdfTemplates
  class Household
    include Virtus.model

    attribute :effective_start_date, DateTime
    attribute :effective_end_date, DateTime

    attribute :primary, PdfTemplates::Member
    attribute :spouse, PdfTemplates::Member
    attribute :dependents, Array[PdfTemplates::Member]
    attribute :monthly_enrollments, Hash[Integer => PdfTemplates::IrsPolicy]
  end
end