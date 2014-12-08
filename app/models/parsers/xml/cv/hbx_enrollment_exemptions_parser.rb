module Parsers::Xml::Cv
  class HbxEnrollmentExemptionParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'hbx_enrollment_exemption'
    namespace 'cv'

    element :id, String, tag: 'id/cv:id'
    element :type, String, tag: 'type'
    element :certificate_number, String, tag: 'certificate_number'
    element :start_date, String, tag: 'start_date'
    element :end_date, String, tag: 'end_date'
  end
end