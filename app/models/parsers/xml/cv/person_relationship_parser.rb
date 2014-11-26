module Parsers::Xml::Cv
  class PersonRelationshipParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person_relationship'
    namespace 'cv'

    element :subject_individual_id, String, xpath: "./cv:subject_individual/cv:id"
    element :object_individual_id, String, xpath: "./cv:object_individual/cv:id"
    element :relationship_uri, String, xpath: "./cv:relationship_uri"

    def to_relationship
      { subject_person_id: subject_individual_id,
        object_person_id: object_individual_id,
        relationship_uri: relationship_uri.split('#').last
      }
    end
  end
end
