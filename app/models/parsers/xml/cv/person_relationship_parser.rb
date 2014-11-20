module Parsers::Xml::Cv
  class PersonRelationshipParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person_relationship'
    namespace 'cv'

    element :subject_person_id, String, xpath: "cv:person_relationship/cv:subject_individual/cv:id"
    element :object_person_id, String, xpath: "cv:person_relationship/cv:object_individual/cv:id"
    element :relationship_kind, String, xpath: "cv:person_relationship/cv:relationship_uri"
  end
end
