module Parsers::Xml::Cv

  class IncomeParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'incomes'
    namespace 'cv'

    xpath_income_prefix = " income"
    xpath_total_income_by_year_prefix = "total_income_by_year"

    element :calendar_year, String, tag:"#{xpath_total_income_by_year_prefix}/cv:calender_year"
    element :total_amount, String, tag:"#{xpath_total_income_by_year_prefix}/cv:total_amount"
    element :amount, String, xpath:"#{xpath_income_prefix}/cv:amount"
    element :type, String, tag:"#{xpath_income_prefix}/cv:type"
    element :frequency, String, tag:"#{xpath_income_prefix}/cv:frequency"

    def to_hash
      {
          calendar_year: calendar_year,
          total_amount: total_amount,
          amount: amount,
          type: type,
          frequency: frequency
      }
    end

  end
end