module Parsers::Xml::Cv

  class IncomeParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'income'
    namespace 'cv'

    element :total_amount, String, tag:"total_amount"
    element :amount, String, tag:"amount"
    element :type, String, tag:"type"
    element :frequency, String, tag:"frequency"
    element :start_date, String, tag:"start_date"
    element :submitted_date, String, tag:"submitted_date"

    def to_hash
      {
          total_amount: total_amount,
          amount: amount,
          kind: type.split('#').last.gsub('-','_'),
          frequency: frequency.split('#').last.gsub('-','_'),
          start_date: start_date,
          submitted_date: submitted_date
      }
    end

  end
end