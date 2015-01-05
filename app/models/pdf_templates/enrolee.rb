module PdfTemplates
  class Enrolee
    include Virtus.model

    attribute :name, String
    attribute :ssn, String
    attribute :dob, String
    attribute :subscriber, Boolean, :default => false
    attribute :spouse, Boolean, :default => false
    attribute :coverage_start_date, String
    attribute :coverage_termination_date, String
  end
end