module Parsers::Xml::Cv

  class ApplicantParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'applicant'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    has_one :person, Parsers::Xml::Cv::PersonParser, tag:'person'
    has_many :person_relationships, Parsers::Xml::Cv::PersonRelationshipParser, xpath:'cv:person_relationships'
    has_one :person_demographics, Parsers::Xml::Cv::PersonDemographicsParser, tag:'person_demographics'
    element :is_primary_applicant, String, tag: 'is_primary_applicant'
    element :tax_household_id, String, tag: 'tax_household_id'
    element :is_coverage_applicant, String, tag: 'is_coverage_applicant'
    element :is_head_of_household, String, tag: 'is_head_of_household'
    has_many :financial_statements, Parsers::Xml::Cv::FinancialStatementParser, xpath:'cv:financial_statements'
    element :is_active, String, tag: 'is_active'

    def to_individual_request(member_id_generator)
      person.individual_request(member_id_generator).merge(person_demographics.individual_request).merge({
        :emails => [],
        :addresses => [],
        :phones => []
      })
    end
    def dob
      Date.parse(person_demographics.birth_date)
    end

    def age
      Ager.new(dob).age_as_of(Date.parse("2015-1-1"))
    end
  end
end
