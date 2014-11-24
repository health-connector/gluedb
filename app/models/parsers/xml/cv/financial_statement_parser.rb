module Parsers::Xml::Cv

  class FinancialStatementParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'financial_statement'
    namespace 'cv'

    element :type, String, tag: "type"

    element :tax_filing_status, String, tag: "tax_filing_status"
    element :is_tax_filing_together, String, tag:"is_tax_filing_together"
    has_many :incomes, Parsers::Xml::Cv::IncomeParser, xpath: "incomes"
    has_many :deductions, Parsers::Xml::Cv::DeductionParser, xpath: "deductions"
    has_many :alternative_benefits, Parsers::Xml::Cv::AlternateBenefitParser, xpath: "alternative_benefits"
    has_many :deductions, String, xpath: "deductions"

  end
end