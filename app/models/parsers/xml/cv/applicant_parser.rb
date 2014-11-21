module Parsers::Xml::Cv

  class ApplicantParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'applicant'
    namespace 'cv'

    element :id, String, tag:'id/cv:id'
    element :tax_household_id, String, xpath:'cv:id'
    has_one :person, Parsers::Xml::Cv::PersonParser, tag:'person'
    has_many :person_relationships, Parsers::Xml::Cv::PersonRelationshipParser, tag:'person_relationships'
    #element :person_demographics, Parsers::Xml::Cv::PersonDemographicsParser, tag:'person_demographics' TODO
    element :is_primary_applicant, Boolean, tag:'is_primary_applicant'
  end
end