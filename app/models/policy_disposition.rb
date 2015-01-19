class PolicyDisposition
  attr_reader :start_date
  attr_reader :end_date
  attr_reader :policy
  attr_reader :enrollees

  def initialize(pol)
    @policy = pol
    @start_date = pol.policy_start
    @end_date = pol.policy_end.blank? ? pol.coverage_period.end : pol.policy_end
    @changes_over_time = @policy.changes_over_time?
    @enrollees = @policy.enrollees.reject do |en|
      en.canceled?
    end
  end

  def changes_over_time?
    @changed_over_time
  end

  def as_of(date, other_plan = nil)
    if !changes_over_time?
      if other_plan.blank?
        return @policy
      end
      clone_pol_with_plan_on(other_plan, date)
    else
      pol_plan = other_plan.blank? ? @policy.plan : other_plan
      clone_pol_with_plan_on(pol_plan, date)
    end
  end

  def clone_pol_with_plan_on(plan, date)
    pol = Policy.new({
      :broker => @policy.broker,
      :employer_id => @policy.employer_id,
      :carrier_to_bill => @policy.carrier_to_bill,
      :carrier_id => @policy.carrier_id,
      :responsible_party_id => @policy.responsible_party_id,
      :applied_aptc => @policy.applied_aptc
    })
    pol.plan = plan
    copied_enrollees = @enrollees.select do |en|
        (en.coverage_start <= date) &&
          ((en.coverage_end.blank?) ||
           (en.coverage_end >= date))
    end
    pol.enrollees = copied_enrollees.map { |ce| clone_enrollee(ce) }
    pc = PolicyCalculator.new
    pc.apply_calculations(pol)
    pol
  end

  def clone_enrollee(en)
    Enrollee.new({
        :coverage_start => en.coverage_start,
        :coverage_end => en.coverage_end,
        :coverage_status => "active",
        :rel_code => en.rel_code,
        :m_id => en.m_id,
        :ben_stat => "active",
        :emp_stat => "active"
    })
  end
end
