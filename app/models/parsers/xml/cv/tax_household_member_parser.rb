module Parsers::Xml::Cv

  class TaxHouseholdMemberParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'tax_household_member'
    namespace 'cv'

    element :id, String, tag: 'id/cv:id'
    has_one :person, Parsers::Xml::Cv::PersonParser, tag:'person'
    element :is_ia_eligible, String, tag:'is_insurance_assistance_eligible'
    element :is_medicaid_chip_eligible, String, tag:'is_medicaid_chip_eligible'
    element :is_subscriber, String, tag:'is_subscriber'
    #element :person_id, String, xpath:'cv:person/cv:id/cv:id'
    #element :person_name_first, String, xpath:'cv:person/cv:person_name/cv:person_surname'
    #element :person_name_first, String, xpath:'cv:person/cv:person_name/cv:person_given_name'

    def to_hash
      {
          id: id,
          is_ia_eligible: is_ia_eligible,
          is_medicaid_chip_eligible: is_medicaid_chip_eligible,
          is_subscriber: is_subscriber
          # //person: person.to_hash
      }
    end

  end

end