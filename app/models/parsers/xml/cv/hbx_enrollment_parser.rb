module Parsers::Xml::Cv
  class HbxEnrollmentParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'hbx_enrollment'
    namespace 'cv'

    element :id, String, tag: 'id/cv:id'

  end
end