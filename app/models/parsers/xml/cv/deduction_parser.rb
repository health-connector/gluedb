module Parsers::Xml::Cv

  class DeductionParser < Parsers::Xml::Cv::IncomeParser

    tag 'deduction'

    xpath_income_prefix = "cv:deduction"
    xpath_total_income_by_year_prefix = "cv:total_deductions_by_year"

  end
end