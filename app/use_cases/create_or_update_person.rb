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

  def member_keys
    [:ssn, :dob, :gender, :hbx_member_id]
  end

  def other_keys
    [:addresses, :emails, :phones]
  end

  def extract_person_properties(request)
    request.reject { |k, _| member_keys.include?(k) || other_keys.include?(k) }
  end

  def extract_member_properties(request)
    request.select { |k, _| member_keys.include?(k) }
  end

  def member_update_properties_from(request)
    member_update_keys = [:ssn, :dob, :gender]
    request.select { |k, _| member_update_keys.include?(k) }
  end

  def extract_and_merge_addresses(person, request)
    address_data = request[:addresses]
    address_data.each do |addy|
      person.update_address(Address.new(addy))
    end
  end

  def extract_and_merge_emails(person, request)
    address_data = request[:emails]
    address_data.each do |addy|
      person.update_email(Email.new(addy))
    end
  end

  def extract_and_merge_phones(person, request)
    address_data = request[:phones]
    address_data.each do |addy|
      person.update_phone(Phone.new(addy))
    end
  end

  def commit(request, listener)
    person, member = @person_finder.find_person_and_member(request)

    member_id = request[:hbx_member_id]

    if person.blank?
      new_person = @person_factory.new(request)
      new_member = @member_factory.new(extract_member_properties(request))
      new_person.members << new_member
      new_person.authority_member_id = member_id
      new_person.save!
      listener.register_person(member_id, new_person, new_member)
    elsif member.blank?
      new_member = @member_factory.new(extract_member_properties(request))
      person.assign_attributes(extract_person_properties(request))
      extract_and_merge_addresses(person, request)
      extract_and_merge_phones(person, request)
      extract_and_merge_emails(person, request)
      person.members << new_member
      person.authority_member_id = member_id
      person.save!
      listener.register_person(member_id, person, new_member)
    else
      person.assign_attributes(extract_person_properties(request))
      member.update_attributes(member_update_properties_from(request))
      extract_and_merge_addresses(person, request)
      extract_and_merge_phones(person, request)
      extract_and_merge_emails(person, request)
      person.save!
      listener.register_person(member_id, person, member)
    end
  end
end
