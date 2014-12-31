module Parsers::Xml::Cv

  class PolicyParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'policy'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    has_one :enrollment, Parsers::Xml::Cv::EnrollmentParser, tag:'enrollment'
    has_many :enrollees, Parsers::Xml::Cv::EnrolleeParser, xpath: 'cv:enrollees'


    def to_hash
      {
          id:id,
          enrollment: enrollment.to_hash,
          enrollees: enrollees.map(&:to_hash)
      }
    end

  end
end