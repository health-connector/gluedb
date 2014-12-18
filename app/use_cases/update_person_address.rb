class UpdatePersonAddress
  def initialize(person_repo, address_changer, change_address_request_factory)
    @person_repo = person_repo
    @address_changer = address_changer
    @change_address_request_factory = change_address_request_factory
  end

  def validate(request, listener)
    fail = false

    person = @person_repo.find_by_id(request[:person_id])

    if(missing_home_address?(request))
      listener.home_address_not_present
      fail = true
    end

    type_count_map = {}
    request[:addresses].each do |address|
      type_count_map[address[:address_type]] ||= 0
      type_count_map[address[:address_type]] += 1
    end

    type_count_map.each_pair do |type, count|
      max = 1
      if(count > max)
        listener.too_many_addresses_of_type({address_type: type, max: max})
        fail = true
      end
    end

    addresses_valid = true
    request[:addresses].each_with_index do |address, idx|
      listener.set_current_address(idx)
      change_address_request = @change_address_request_factory.from_person_update_request(address, {
              :person_id => request[:person_id], 
              :current_user => request[:current_user] 
      })
      addresses_valid = addresses_valid && @address_changer.validate(change_address_request, listener)
    end

    if listener.has_errors?
      fail = true
    end

    unless addresses_valid
      fail = true
    end

    !fail
  end

  def execute(request, listener)
    if validate(request, listener)
      commit(request)
      listener.success
    else
      listener.fail
    end
  end

  def commit(request)
    person = @person_repo.find_by_id(request[:person_id])

    address_deleter = DeleteAddress.new(NullPolicyMaintenance.new, @person_repo)

    Address::TYPES.each do |t|
      request_address = request[:addresses].detect { |a| a[:address_type] == t }
      if (request_address.nil?)
        address_deleter.commit({
          :person_id => request[:person_id], 
          :type => t,  
          :current_user => request[:current_user] 
          }
        )
      else
        change_address_request = @change_address_request_factory.from_person_update_request(request_address, {
              :person_id => request[:person_id],
              :current_user => request[:current_user] 
          })
        @address_changer.commit(change_address_request)
      end
    end
    person.updated_by = request[:current_user]
    person.save!
  end

  protected

  def missing_home_address?(request)
    request[:addresses].detect { |a| a[:address_type] == 'home' }.nil?
  end
end
