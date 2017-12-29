module RemoteResources
  class PersonRelationship
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person_relationship'
    namespace 'cv'

    element :relationship_uri, String,  tag: "relationship_uri"
    element :subject_individual_id, String, tag: "subject_individual/cv:id"
    element :object_individual_id, String, tag: "object_individual/cv:id"

    def relationship
      Maybe.new(relationship_uri).split("#").last.value
    end

    def subject_individual_member_id
      Maybe.new(subject_individual_id).split("#").last.value
    end

    def object_individual_member_id
      Maybe.new(object_individual_id).split("#").last.value
    end

    def glue_relationship
      case relationship
      when "spouse", "life_partner", "domestic_partner"
        "spouse"
      when "court_appointed_guardian"
        "ward"
      else
        "child"
      end
    end

  end
end
