class CreateOrUpdatePerson
  def initialize(p_finder, p_factory, m_factory)
    @person_finder = p_finder
    @person_factory = p_factory
    @member_factory = m_factory
  end

  def validate(request, listener)
    person = nil
    member = nil
    begin
      person, member = @person_finder.find_person_and_member(request)
    rescue PersonMatchStrategies::AmbiguiousMatchError => e
      listener.person_match_error(e.message)
      return false
    end

    new_person = @person_factory.new(request)
    return false unless validate_person(new_person, listener)
    new_member = @member_factory.new(request)
    return false unless validate_member(new_member, listener)
    true
  end

  def validate_member(member, listener)
    if !member.valid?
      listener.invalid_member(member.errors.to_hash)
      return false
    end
    true
  end

  def validate_person(person, listener)
    if !person.valid?
      listener.invalid_person(person.errors.to_hash)
      return false
    end
    true
  end

  def commit(request, listener)
    person, member = @person_finder.find_person_and_member(request)
  end
end
