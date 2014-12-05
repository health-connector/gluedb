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

    has_many :hbx_enrollments, Parsers::Xml::Cv::HbxEnrollmentParser, tag: 'hbx_enrollments'

    def individual_requests(member_id_generator)
      applicants.map do |applicant|
        applicant.to_individual_request(member_id_generator)
      end
    end

    def primary_applicant
      applicants.detect{|applicant| applicant.id == primary_applicant_id }
    end

    def policies_enrolled
      ['772']
    end

    def yearly_income(calender_year)
      total_income = 0.0
      tax_households.each do |tax_household|
        yearly_incomes = tax_household.to_hash[:total_incomes_by_year]
        income_record = yearly_incomes.detect{|income| income[:calendar_year] == calendar_year}
        total_income += income_record[:total_amount].to_f if income_record
      end
      sprintf("%.2f", total_income)
    end
  end
end
