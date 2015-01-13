module Parsers::Xml::Cv
  class FinancialStatement
    include NodeUtils
    TAX_FILING_STATUS_MAP = {
      "non filer" => "non_filer",
      "tax dependent" => "tax_dependent",
      "tax filer" => "tax_filer"
    }
    def initialize(parser)
      @parser = parser
    end

    def is_primary_applicant
      @parser.at_xpath('./ns1:is_primary_applicant', NAMESPACES).text.downcase == 'true'
    end

    def tax_filing_status
      TAX_FILING_STATUS_MAP[first_text('./ns1:tax_filing_status').downcase]
    end

    def is_tax_filing_together
      @parser.at_xpath('./ns1:is_tax_filing_together', NAMESPACES).text.downcase == 'true'
    end

    def is_enrolled_for_es_coverage
      @parser.at_xpath('./ns1:is_enrolled_for_es_coverage', NAMESPACES).text.downcase == 'yes'
    end

    def is_without_assistance
      !(@parser.at_xpath('./ns1:is_without_assistance', NAMESPACES).text.downcase == 'no')
    end

    def is_ia_eligible
      @parser.at_xpath('./ns1:is_without_assistance', NAMESPACES).text.downcase == 'true'
    end

    def incomes
      results = []

      elements = @parser.xpath('./ns1:incomes/ns1:income', NAMESPACES)
      elements.each { |i| results << Parsers::Xml::Cv::Income.new(i) }

      results.reject(&:empty?)
    end

    def deductions
      results = []

      elements = @parser.xpath('./ns1:deductions/ns1:deduction', NAMESPACES)
      elements.each { |i| results << Parsers::Xml::Cv::Deduction.new(i) }

      results.reject(&:empty?)
    end

    def alternative_benefits
      results = []

      elements = @parser.xpath('./ns1:alternative_benefits/ns1:alternative_benefit', NAMESPACES)
      elements.each { |i| results << Parsers::Xml::Cv::AlternativeBenefit.new(i) }

      results.reject(&:empty?)
    end

    def submitted_date
      first_date('./ns1:submitted_date')
    end

    def to_request
      {
        :submission_date => submitted_date,
        :is_primary_applicant => is_primary_applicant,
        :tax_filing_status => tax_filing_status,
        :is_tax_filing_together => is_tax_filing_together,
        :is_enrolled_for_es_coverage => is_enrolled_for_es_coverage,
        :is_without_assistance => is_without_assistance,
        :is_ia_eligible => is_ia_eligible,
        :alternate_benefits => alternative_benefits.map(&:to_request),
        :deductions => deductions.map(&:to_request),
        :incomes => incomes.map(&:to_request)
      }
    end
  end
end
