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
      member_attributes = request[:demographics]
      if member.nil?
        member_attributes.merge({:hbx_member_id => request[:hbx_member_id]})
      end
      member ||= person.members.new
      member.assign_attributes(member_attributes)
      member.save!

      person_attributes = request[:person].inject({}) do |person, (k, v)|
        person[k] = v if v.is_a?(String)
        person
      end
      person.attributes = person_attributes
      person.save!

      request[:person][:addresses].each do |address|
        if current_address = person.phones.detect{|x| x.address_type == phone[:address_type]}
          current_address.update_attributes(address)
        else
          new_address = person.addresses.new(address)
          new_address.save!
        end
      end

      request[:person][:phones].each do |phone|
        if current_phone = person.phones.detect{|x| x.phone_type == phone[:phone_type]}
          current_phone.update_attributes(phone)
        else
          new_phone = person.phones.new(phone)
          new_phone.save!
        end
      end

      request[:person][:emails].each do |email|
        if current_email = person.emails.detect{|x| x.email_type == email[:email_type]}
          current_email.update_attributes(email)
        else
          new_email = person.emails.new(email)
          new_email.save!
        end
      end

      listener.register_person(request[:member], person, member)
    else
      @create_person_factory.commit(request)
    end
  end
end