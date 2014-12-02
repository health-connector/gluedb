module Parsers::Xml::Cv

  class IncomeByYearParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'total_incomes_by_year'
    namespace 'cv'

    element :calendar_year, String, tag: 'calendar_year'
    element :total_amount, String, tag: 'total_amount'

    def to_hash
      {
          calendar_year: calendar_year,
          total_amount: total_amount
      }
    end
  end
end