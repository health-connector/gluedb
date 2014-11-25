module Parsers::Xml::Cv

  class PhoneParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'phone'
    namespace 'cv'

    element :type, String, tag: "type"
    element :country_code, String, tag: "country_code"
    element :area_code, String, tag: "area_code"
    element :phone_number, String, tag: "phone_number"
    element :full_phone_number, String, tag: "full_phone_number"
    element :extension, String, tag: "extension"
    element :is_preferred, String, tag: "is_preferred"

    def request_hash
      {
          phone_type:type.split("#").last,
          phone_number:full_phone_number
      }
    end
  end
end