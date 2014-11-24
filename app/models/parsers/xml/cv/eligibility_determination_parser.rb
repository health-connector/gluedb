module Parsers::Xml::Cv
  class EligibilityDeterminationParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'eligibility_determination'
    namespace 'cv'

    element :id, String, tag: 'id/cv:id'
    has_one :household_state, String, tag:'household_state'
    element :maximum_aptc, String, tag:'maximum_aptc'
    element :csr_percent, String, tag:'csr_percent'
    element :determination_date, String, tag:'determination_date'
    has_many :applicants, Parsers::Xml::Cv::ApplicantParser, tag:'applicant'

  end
end