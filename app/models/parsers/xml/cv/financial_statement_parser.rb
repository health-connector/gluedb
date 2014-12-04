module Parsers::Xml::Cv

  class FinancialStatementParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'financial_statement'
    namespace 'cv'

    element :type, String, tag: "type"

    element :tax_filing_status, String, tag: "tax_filing_status"
    element :is_tax_filing_together, String, tag:"is_tax_filing_together"
    has_many :incomes, Parsers::Xml::Cv::IncomeParser, xpath: "cv:incomes"
    has_many :alternative_benefits, Parsers::Xml::Cv::AlternateBenefitParser, xpath: "cv:alternative_benefits"
    has_many :deductions, Parsers::Xml::Cv::DeductionParser, xpath: "cv:deductions"

    def to_hash
      {
          type: type,
          is_tax_filing_together: is_tax_filing_together,
          incomes: incomes.map do |income|
            income.to_hash
          end,
          alternative_benefits: alternative_benefits.map do |alternative_benefit|
            alternative_benefit.to_hash
          end,
          deductions: alternative_benefits.map do |deduction|
            deduction.to_hash
          end
      }
    end
  end
end