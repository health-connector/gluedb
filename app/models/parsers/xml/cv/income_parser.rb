module Parsers::Xml::Cv

  class IncomeParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'income'
    namespace 'cv'

    element :calendar_year, String, tag:"calender_year"
    element :total_amount, String, tag:"total_amount"
    element :amount, String, tag:"amount"
    element :type, String, tag:"type"
    element :frequency, String, tag:"frequency"

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