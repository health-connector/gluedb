module Parsers::Xml::Cv
  class PersonRelationshipParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person_relationship'
    namespace 'cv'

    element :subject_individual_id, String, xpath: "./cv:subject_individual/cv:id"
    element :object_individual_id, String, xpath: "./cv:object_individual/cv:id"
    element :relationship_uri, String, xpath: "./cv:relationship_uri"
  end
end
