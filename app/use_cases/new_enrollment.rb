class NewEnrollment
  class PersonMappingListener < SimpleDelegator
    attr_reader :person_map

    def initialize(obj)
      super(obj)
      @person_map = {}
    end

    def register_person(m_id, person, member)
      @person_map[m_id] = [person, member]
    end
  end


  def initialize(update_person_uc = CreateOrUpdatePerson.new, create_policy_uc = Policies::CreatePolicy.new)
    @update_person_use_case = update_person_uc
    @create_policy_use_case = create_policy_uc
  end

  def execute(request, orig_listener)
    listener = PersonMappingListener.new(orig_listener)
    failed = false
    individuals = request[:individuals]
    policies = request[:policies]
    if individuals.blank?
      listener.no_individuals
      listener.fail
      return
    else
      people_failed = false
      individuals.each_with_index do |ind, idx|
        listener.set_current_person(idx)
        people_failed = people_failed || !@update_person_use_case.validate(ind, listener)
      end
      failed = failed || people_failed
    end
    if policies.blank?
      listener.no_policies
      listener.fail
      return
    else
      policies_failed = false
      policies.each_with_index do |pol, idx|
        listener.set_current_policy(idx)
        policies_failed = policies_failed || !@create_policy_use_case.validate(pol, listener)
      end
      failed = failed || policies_failed
      if failed
        listener.fail
        return
      end
    end

    if failed
      listener.fail
    else
      individuals.each do |ind|
        @update_person_use_case.commit(ind, listener)
      end
      policies.each do |pol|
        pol_properties = remap_enrollees(pol, listener)
        @create_policy_use_case.commit(pol_properties, listener)
      end
      listener.success
    end
  end

  def remap_enrollees(pol, listener)
    pol_hash = pol.dup
    enrollees = pol_hash[:enrollees]
    updated_enrollees = enrollees.map do |en|
      updated_en = en.dup
      updated_en[:m_id] = listener.person_map[en[:m_id]].last.hbx_member_id
      updated_en
    end
    pol_hash[:enrollees] = updated_enrollees
    pol_hash
  end

end
