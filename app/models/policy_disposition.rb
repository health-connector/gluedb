class PolicyDisposition
  attr_reader :start_date
  attr_reader :end_date

  def initialize(pol)
    @policy = pol
    @start_date = pol.policy_start
    @end_date = pol.coverage_end.blank? ? pol.coverage_period.end : pol.coverage_end
    @changes_over_time = @policy.changes_over_time?
  end

  def changes_over_time?
    @changed_over_time
  end

  def as_of(date, other_plan = nil)
    if !changes_over_time?
      if other_plan.blank?
        return @policy
      end
    end
  end
end
