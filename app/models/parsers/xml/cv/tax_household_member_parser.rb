module Parsers::Xml::Cv

  class TaxHouseholdMemberParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'irs_group'
    namespace 'cv'

    element :id, String, tag: 'id'
    has_one :person, Parsers::Xml::Cv::PersonParser, tag:'person'

    def to_hash
      {
          id: id,
          person: person.individual_request
      }
    end

  end

end