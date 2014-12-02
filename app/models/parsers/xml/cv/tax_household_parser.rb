module Parsers::Xml::Cv

  class TaxHouseholdParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'tax_household'
    namespace 'cv'

    element :id, String, tag: 'id/cv:id'
    element :primary_applicant_id, String, tag: 'primary_applicant_id/cv:id'
    element :tax_household_size_total_count, String, tag: 'tax_household_size/cv:total_count'
    has_many :total_incomes_by_year,  Parsers::Xml::Cv::IncomeByYearParser, xpath: 'cv:total_incomes_by_year'
    element :is_active, Boolean, tag:'is_active'
    has_many :tax_household_members, Parsers::Xml::Cv::TaxHouseholdMemberParser, xpath: 'cv:tax_household_members'


    def to_hash
      {
          id: id,
          primary_applicant_id: primary_applicant_id,
          total_count: tax_household_size_total_count,
          total_incomes_by_year: total_incomes_by_year.map do |total_income_by_year|
            total_incomes_by_year.to_hash
          end
      }
    end
  end
end