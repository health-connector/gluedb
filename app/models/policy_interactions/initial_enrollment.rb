module PolicyInteractions
  class InitialEnrollment
    def qualifies?(old_policies, new_policy)
      return false if (old_policies.any? { |op| new_policy.coverage_period.overlaps?(op.coverage_period) })
      to_check_for_previous = old_policies.select do |op|
        op.coverage_period.end == new_policy.coverage_period.begin - 1.day
      end
      return false if (to_check_for_previous.any? { |op| !op.terminated? })
      true
    end
  end
end
