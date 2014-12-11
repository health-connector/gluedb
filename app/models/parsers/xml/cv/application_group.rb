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

    has_many :eligibility_determinations, Parsers::Xml::Cv::EligibilityDeterminationParser, xpath: 'cv:eligibility_determinations'

    has_many :hbx_enrollments, Parsers::Xml::Cv::HbxEnrollmentParser, tag: 'hbx_enrollments'

    def individual_requests(member_id_generator, p_tracker)
      applicants.map do |applicant|
        applicant.to_individual_request(member_id_generator, p_tracker)
      end
    end

    def primary_applicant
      if applicants.size == 1
        applicants.first
      else
        applicants.detect{|applicant| applicant.id == primary_applicant_id }
      end
    end

    def policies_enrolled
      hbx_enrollments.map{|enrollment| enrollment.policy_id }
    end

    def to_hash
      response = {
          e_case_id:e_case_id,
          submitted_date:submitted_date,
          irs_groups: irs_groups.map do |irs_group|
            irs_group.to_hash
          end,
          tax_households: tax_households.map do |tax_household|
            tax_household.to_hash
          end,
          applicants: applicants.map do |applicant|
            applicant.to_hash
          end,
          eligibility_determinations: eligibility_determinations.map do |eligibility_determination|
            eligibility_determination.to_hash
          end
      }
    end
  end
end
