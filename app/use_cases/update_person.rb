class UpdatePerson

  def initialize
    @create_person_factory = CreatePerson.new
  end

  def validate(request, listener)
    fail = false
    begin
      person, member = person_and_member_match(request)
      if person
        person.assign_attributes(request[:person])
        if !person.valid?
          listener.invalid_person(person.errors.to_hash)
          fail = true
        end
        member ||= person.members.new
        member.attributes = request[:demographics]
        if !member.valid?
          listener.invalid_member(member.errors.to_hash)
          fail = true
        end
      else
        fail = !@create_person_factory.validate(request, listener)
      end
    rescue PersonMatchStrategies::AmbigiousMatchError => error
      listener.person_match_error(error.message)
    end

    !fail
  end

  def execute(request, listener)
    if validate(request, listener)
      commit(request)
      listener.success
    else
      listener.fail
      endx
    end
  end

  def person_and_member_match(request)
    options = {
      member_id: request[:hbx_member_id],
      name_first: request[:person][:name_first],
      name_last: request[:person][:name_last],
      ssn: request[:demographics][:ssn],
      dob: request[:demographics][:dob]
    }

    PersonMatchStrategies::Finder.find_person_and_member(options)
  end

  def commit(request)
    person, member = person_and_member_match(request)
    if person
      member ||= person.members.new
      member.attributes = request[:demographics]
      member.save
      # update person
      # update emails
      # update phones
      # update addresses
    else
      @create_person_factory.commit(request)
    end
  end
end