module Parsers::Xml::Cv

  class EmailParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'email'
    namespace 'cv'

    element :type, String, tag: "type"
    element :email_address, String, tag: "email_address"

    def request_hash
      {
          email_type:type.split("#").last,
          email_address:email_address
      }
    end

    def to_hash
          request_hash
    end
  end
end