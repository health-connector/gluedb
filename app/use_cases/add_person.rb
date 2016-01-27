class AddPerson
  def initialize()
  end

  def execute(person, relationship)
    group = person.family
    
    relationship = (group.person_relationships.empty?) ? 'self' : relationship

    subject_person = (relationship == 'self') ? person.id : group_representative_id(group)

    group.person_relationships << PersonRelationship.new(subject_person: subject_person, relationship_kind: relationship, object_person: person.id)

    group.save
  end

  private 
  def group_representative_id(group)
    group.person_relationships.detect { |r| r.relationship_kind == 'self'}.object_person
  end
end
