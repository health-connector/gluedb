module Parsers::Xml::Cv
  class ApplicationGroup
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"

    tag 'application_group'

    namespace 'cv'

    element :primary_applicant_id, String, xpath: "cv:primary_applicant_id/cv:id"

    element :submitted_date, String, :tag=> "submitted_date"

    element :e_case_id, String, xpath: "cv:id/cv:id"

    has_many :applicants, Parsers::Xml::Cv::ApplicantParser, xpath: "cv:applicants"

    has_many :tax_households, Parsers::Xml::Cv::TaxHouseholdParser, xpath:'cv:tax_households'

    has_many :irs_groups, Parsers::Xml::Cv::IrsGroupParser, tag: 'irs_groups'

    has_many :eligibility_determinations, Parsers::Xml::Cv::EligibilityDeterminationParser, tag: 'eligibility_determinations'

    def individual_requests(member_id_generator)
      applicants.map do |applicant|
        applicant.to_individual_request(member_id_generator)
      end
    end
  end
end
