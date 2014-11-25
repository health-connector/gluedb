class UpdatePersonErrorCatcher
  def initialize(person)
    @person = person
    @current_address = 0
  end

  def home_address_not_present
    @person.errors.add(:address_type, " -- Home addresses is required.")
  end

  def set_current_address(idx)
    @current_address = idx
  end

  def too_many_addresses_of_type(details)
    @person.errors.add(:address_type, " -- Too many #{details[:address_type]} addresses. Only #{details[:max]} allowed.")
  end

  def no_such_person(details)
    @person.errors.add(:address_type, "No such person (id: #{details[:person_id]}")
  end

  def invalid_address(errors)
    errors.each_pair do |k, v|
      err_list = Array(v)
      err_list.each do |err|
        @person.addresses[@current_address].errors.add(k, err)
      end
    end
  end

  def no_active_policies(details = {})
    @person.errors.add(:policies, "-- No active policies.")
  end

  def too_many_health_policies(details = {})
    @person.errors.add(:policies, "-- Too many health policies.")
  end

  def too_many_dental_policies(details = {})
    @person.errors.add(:policies, "-- Too many dental policies")
  end

  def responsible_party_on_policy(details = {})
    @person.errors.add(:policies, "-- Policy has a responsible party.")
  end

  def has_errors?
    !@person.errors.empty?
  end

  def success
    raise NotImplementedError
  end

  def fail
    raise NotImplementedError
  end
end

