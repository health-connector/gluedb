module Parsers::Xml::Cv

  class EmployerLinkParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'employer_link'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    element :name, String, tag: "name"
    element :dba, String, tag: "dba"

    def to_hash
      {
          id:id,
          name:name,
          dba:dba
      }
    end
  end
end