module Parsers::Xml::Cv

  class TaxHouseholdParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'tax_household'
    namespace 'cv'

    element :id, String, tag: 'id'
    element :primary_applicant_id, String, tag: 'primary_applicant_id'
    element :tax_household_size, String, tag: 'tax_household_size'
    element :total_incomes_by_year, String, tag: 'total_incomes_by_year'
    element :is_active, Boolean, tag:'is_active'
    has_many :tax_household_members, Parsers::Xml::Cv::TaxHouseholdMemberParser, tag: 'tax_household_members'
  end
end