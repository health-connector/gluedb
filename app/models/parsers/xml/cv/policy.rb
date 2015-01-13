module Parsers::Xml::Cv

  class Policy
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'policy'
    namespace 'cv'

    element :id, String, tag: "id"

    has_one :enrollment, Parsers::Xml::Cv::EnrollmentParser, tag:'enrollment'

  end
end