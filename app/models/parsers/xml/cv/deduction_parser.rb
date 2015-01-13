module Parsers::Xml::Cv

  class DeductionParser

    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"

    namespace 'cv'
    tag 'deduction'


    element :total_amount, String, tag:"total_amount"
    element :amount, String, tag:"amount"
    element :type, String, tag:"type"
    element :frequency, String, tag:"frequency"
    element :start_date, String, tag:"start_date"
    element :submitted_date, String, tag:"submitted_date"

    def to_hash
      response = {
          total_amount: total_amount,
          amount: amount,
          amount_in_cents: (amount.to_f * 100).to_i,
          frequency: frequency.split('#').last.gsub('-','_'),
          start_date: start_date,
          submitted_date: submitted_date
      }

      response[:kind] = type.split('#').last.gsub('-','_') unless type.blank? # don't add :kind if its not blank

      response
    end

  end
end