module Parsers::Xml::Cv

  class AlternateBenefitParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'alternative_benefit'
    namespace 'cv'

    element :type, String, tag:"type"
    element :start_date, String, tag:"start_date"
    element :end_date, String, tag:"end_date"
    element :submitted_date, String, tag:"submitted_date"

    def sanitize_type
      kind = type.split('#').last
      kind = kind.gsub('-','_') if kind
    end

    def to_hash
      {
          start_date: start_date,
          end_date: end_date,
          submitted_date: submitted_date,
          kind: sanitize_type
      }
    end

  end
end