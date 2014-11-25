module Parsers::Xml::Cv

  class DeductionParser

    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"

    namespace 'cv'
    tag 'deduction'

    xpath_income_prefix = "cv:deduction"
    xpath_total_income_by_year_prefix = "cv:total_deductions_by_year"

    element :calendar_year, String, tag:"#{xpath_total_income_by_year_prefix}/cv:calender_year"
    element :total_amount, String, tag:"#{xpath_total_income_by_year_prefix}/cv:total_amount"
    element :amount, String, xpath:"#{xpath_income_prefix}/cv:amount"
    element :type, String, tag:"#{xpath_income_prefix}/cv:type"
    element :frequency, String, tag:"#{xpath_income_prefix}/cv:frequency"

  end
end