module Parsers::Xml::Cv

  class TaxHouseholdMemberParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'tax_household_member'
    namespace 'cv'

    has_one :person, Parsers::Xml::Cv::PersonParser, tag:'person'
    element :is_ia_eligible, String, tag:'is_insurance_assistance_eligible'
    element :is_medicaid_chip_eligible, String, tag:'is_medicaid_chip_eligible'
    element :is_subscriber, String, tag:'is_subscriber'

    def to_hash
      {
          person_id: person.id,
          is_ia_eligible: is_ia_eligible,
          is_medicaid_chip_eligible: is_medicaid_chip_eligible,
          is_subscriber: is_subscriber
      }
    end

  end

end