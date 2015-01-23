class RenewalDetermination

  def initialize(p_finder = PersonMatchStrategies::Finder, pl_finder = Plan)
    @person_finder = p_finder
    @plan_finder = pl_finder
  end

  def validate(request, listener)
    pols = request[:policies]
    people = request[:individuals]
    s_enrollee = pols.first[:enrollees].detect do |enrollee|
      enrollee[:rel_code] == 'self'
    end
    if s_enrollee.nil?
      listener.no_subscriber_for_policies
      return false
    end
    enrollee = Enrollee.new(s_enrollee)
    coverage_start = enrollee.coverage_start
    member_id = s_enrollee[:m_id]
    s_person = people.detect do |perp|
      perp[:hbx_member_id] == member_id
    end
    person = nil
    member = nil
    begin
      person, member = @person_finder.find_person_and_member(s_person)
    rescue PersonMatchStrategies::AmbiguousMatchError => e
      listener.person_match_error(e.message)
      return false
    end
    if member.nil?
      return true
    end
    policies = person.policies
    return true if policies.empty?
    pols.each do |policy|
      hios_id = policy[:hios_id]
      plan_year = policy[:plan_year]
      eg_id = policy[:enrollment_group_id]
      plan = @plan_finder.find_by_hios_id_and_year(hios_id, plan_year)
      employer_fein = policy[:employer_fein]
      employer = nil
      if !employer_fein.blank?
        employer = Employer.find_for_fein(employer_fein)
        if employer.blank?
          listener.employer_not_found(:fein => employer_fein)
          return false
        end
      end
      if plan.blank?
        listener.plan_not_found(:hios_id => hios_id, :plan_year => plan_year)
        return false
      end
      if spot_carrier_switch(listener, coverage_start, eg_id, plan, policies, employer)
        return false
      end
    end
    true
  end

  def spot_carrier_switch(listener, start_date, eg_id, plan, policies, employer)
    coverage_end = Date.new(start_date.year, 12, 31)
    if !employer.blank?
      py = employer.plan_year_for(start_date)
      coverage_end = py.end_date
    end
    coverage_period = (start_date..coverage_end)
    new_policy = OpenStruct.new(:coverage_period => coverage_period, :carrier_id => plan.carrier_id)
    policies_to_check = policies.reject do |pol|
      pol.canceled? || (pol.policy_start == coverage_start) || (pol.coverage_type.downcase != plan.coverage_type.downcase)
    end
    interactions = [
      ::PolicyInteractions::InitialEnrollment.new,
      ::PolicyInteractions::Renewal.new,
      ::PolicyInteractions::PlanChange.new
    ]
    cs_renewals = policies_to_check.select do |pol|
      !interactions.any? { |pi| pi.qualfies?([pol], new_policy) }
    end
    cs_renewals.each do |op|
      listener.carrier_switch_renewal(
        :new_enrollment_group_id => eg_id,
        :old_policy => {
          :enrollment_group_id => op.eg_id,
          :policy_id => op.id
        }
      )
    end
    cs_renewals.any?
  end
end
