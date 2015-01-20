module Parsers::Xml::Cv
  class FamilyParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"

    tag 'application_group'

    namespace 'cv'

    element :primary_applicant_id, String, xpath: "cv:primary_applicant_id/cv:id"

    element :application_type, String, tag: 'application_type'

    element :renewal_consent_applicant_id, String, tag: 'renewal_consent_applicant_id/cv:id'

    element :renewal_consent_through_year, String, tag: 'renewal_consent_through_year'

    element :submitted_date, String, :tag=> "submitted_date"

    element :e_case_id, String, xpath: "cv:id/cv:id"

    has_many :family_members, Parsers::Xml::Cv::ApplicantParser, xpath: "cv:applicants"

    has_many :tax_households, Parsers::Xml::Cv::TaxHouseholdParser, xpath:'cv:tax_households'

    has_many :irs_groups, Parsers::Xml::Cv::IrsGroupParser, xpath: "cv:irs_groups"

    has_many :hbx_enrollments, Parsers::Xml::Cv::HbxEnrollmentParser, xpath: "cv:hbx_enrollments"


    def individual_requests(member_id_generator, p_tracker)
      family_members.map do |applicant|
        applicant.to_individual_request(member_id_generator, p_tracker)
      end
    end

    def primary_applicant
      if family_members.size == 1
        family_members.first
      else
        family_members.detect{|applicant| applicant.id == primary_applicant_id }
      end
    end

    def policies_enrolled
      hbx_enrollments.map{|enrollment| enrollment.policy_id }
    end

    def to_hash(p_tracker=nil)

      response = {
          e_case_id:e_case_id.split("#").last,
          submitted_at:submitted_date,
          irs_groups: irs_groups.map do |irs_group|
            irs_group.to_hash
          end,
          tax_households: tax_households.map do |tax_household|
            tax_household.to_hash
          end,
          family_members: family_members.map do |applicant|
            applicant.to_hash(p_tracker)
          end
      }

      response[:application_type] = application_type.split('#').last  if application_type
      response[:renewal_consent_applicant_id] = renewal_consent_applicant_id if renewal_consent_applicant_id
      response[:renewal_consent_through_year] = renewal_consent_through_year if renewal_consent_through_year
      response
    end
  end
end
