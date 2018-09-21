module Parsers::Xml::Cv

  class EmployerLinkParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'employer_link'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    element :name, String, tag: "name"
    element :dba, String, tag: "dba"


    has_many :addresses, Parsers::Xml::Cv::AddressParser, tag: "addresses/cv:address"
    # has_one :phone, Parsers::Xml::Cv::PhoneParser, xpath: "phone"

    def address_requests
      addresses.map(&:request_hash)
    end

    def to_hash
      binding.pry
      {
          id:id,
          name:name,
          dba:dba,
          addresses: addresses,
          # phones: phone

      }
    end
  end
end