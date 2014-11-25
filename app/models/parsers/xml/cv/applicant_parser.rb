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
    has_many :financial_statements, Parsers::Xml::Cv::FinancialStatementParser, tag:'financial_statements'


    def dob
      Date.parse(person_demographics.birth_date)
    end

    def age
      Ager.new(dob).age_as_of(Date.parse("2015-1-1"))
    end
  end
end