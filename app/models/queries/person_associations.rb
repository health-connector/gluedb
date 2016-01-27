module Queries
  class PersonAssociations
    def initialize(person)
      @person = person
    end


    def policies
      Policy.where(
        { "enrollees.m_id" =>
          {"$in" => @person.members.map(&:hbx_member_id)}
      }
      )
    end

    def families
      Family.where(
        "$or" => [
          {
            "person_relationships.subject_person" => @person._id
          },
          {
            "person_relationships.object_person" => @person._id
          }
        ]
      )
    end
  end
end
