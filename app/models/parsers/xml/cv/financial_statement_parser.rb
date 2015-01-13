module Parsers::Xml::Cv

  class FinancialStatementParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'financial_statement'
    namespace 'cv'

    element :type, String, tag: "type"
    element :is_tax_filing_together, String, tag:"is_tax_filing_together"
    element :tax_filing_status, String, tag:"tax_filing_status"
    has_many :incomes, Parsers::Xml::Cv::IncomeParser, xpath: "cv:incomes"
    has_many :alternative_benefits, Parsers::Xml::Cv::AlternateBenefitParser, xpath: "cv:alternative_benefits"
    has_many :deductions, Parsers::Xml::Cv::DeductionParser, xpath: "cv:deductions"

    def to_hash
      {
          type: type,
          is_tax_filing_together: is_tax_filing_together,
          tax_filing_status: tax_filing_status.split('#').last.gsub('-','_'),
          incomes: incomes.map do |income|
            income.to_hash
          end,
          alternative_benefits: alternative_benefits.map do |alternative_benefit|
            alternative_benefit.to_hash
          end,
          deductions: deductions.map do |deduction|
            deduction.to_hash if deduction.to_hash.has_key?(:kind)
          end - [nil] #if :kind is absent, reject the deduction. nil =  cases where :kind = nil

      }
    end
  end
end