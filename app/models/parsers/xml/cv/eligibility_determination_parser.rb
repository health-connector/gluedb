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

    def to_hash
      {
          id:id,
          household_state: household_state,
          maximum_aptc: maximum_aptc,
          csr_percent: csr_percent,
          determination_date: determination_date,
          to_individual_requests: applicants.map do |applicant|
            applicant.to_individual_request
          end,
          to_relationships: applicants.map do |applicant|
            applicant.to_relationship
          end
      }
    end

  end
end