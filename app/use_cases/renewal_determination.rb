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
      eg_id = policy = [:enrollment_group_id]
      plan = @plan_finder.find_by_hios_id_and_year(hios_id, plan_year)
      if plan.blank?
        listener.plan_not_found(:hios_id => hios_id, :plan_year => plan_year)
        return false
      end
      # TODO: Check if content of enrollees differs
      renewal_threshold = coverage_start - 1.day
      date_market_different_carrier = policies.select do |pol|
        (pol.plan.coverage_type == plan.coverage_type) &&
          pol.active_as_of?(renewal_threshold) &&
          (pol.subscriber.coverage_end != renewal_threshold) &&
          (pol.plan.carrier_id != plan.carrier_id)
      end
      if date_market_different_carrier.any?
        date_market_different_carrier.each do |op|
        listener.carrier_switch_renewal(
          :new_enrollment_group_id => eg_id,
          :old_policy => {
            :enrollment_group_id => op.eg_id,
            :policy_id => op.id
          }
        )
        end
        return false
      end
      date_market_renewal = policies.select do |pol|
        (pol.plan.coverage_type == plan.coverage_type) &&
          pol.active_as_of?(renewal_threshold)
      end
      date_market_renewal.each do |r_pol|
        begin
        candidate_enrollees = r_pol.enrollees.select do |en|
          r_pol.active_on_date_for?(renewal_threshold, en.m_id) &&
            (en.coverage_end.blank? || (en.coverage_end > renewal_threshold))
        end
        if (candidate_enrollees.length != policy[:enrollees].length)
          listener.enrollees_changed_for_renewal({
            :old_policy => candidate_enrollees.length,
            :new_policy => policy[:enrollees].length
          })
        end
        rescue
          puts request.inspect
          puts policy.inspect
          raise policy.inspect
        end
      end
    end
    true
  end
end
