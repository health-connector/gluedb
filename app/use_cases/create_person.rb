class CreatePerson

  def initialize(person_factory = Person)
    @person_factory = person_factory
  end

  def validate(request, listener)
    fail = false
    person = @person_factory.new(request[:person])
    if !person.valid?
      listener.invalid_person(person.errors.to_hash)
      fail = true
    end

    member = person.members.new
    member.attributes = request[:demographics]
    if !member.valid?
      listener.invalid_member(member.errors.to_hash)
      fail = true
    end

    !fail
  end

  def execute(request, listener)
    if validate(request, listener)
      commit(request, listener)
      listener.success
    else
      listener.fail
    end
  end

  def commit(request, listener)
    person = @person_factory.create!(request[:person])
    member = person.members.new(request[:demographics])
    member.save!
    listener.register_person(request[:member], person, member) 
  end
end