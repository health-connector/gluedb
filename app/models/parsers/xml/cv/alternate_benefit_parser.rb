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

  end
end