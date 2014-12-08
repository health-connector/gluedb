module Parsers::Xml::Cv
  class EnrollmentParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'enrollment'
    namespace 'cv'

    element :premium_amount_total, String, tag: "premium_amount_total"
    element :total_responsible_amount, String, tag: "total_responsible_amount"

    has_one :plan, Parsers::Xml::Cv::PlanParser, tag:'plan'
  end
end