module PolicyInteractions
  class PlanChange
    def qualifies?(old_policies, new_policy)
      return false if old_policies.empty?
      to_check_for_previous = old_policies.select do |op|
        new_policy.coverage_period.overlaps?(op.coverage_period) &&
          (op.carrier_id == new_policy.carrier_id)
      end
      return true if to_check_for_previous.any?
      false
    end
  end
end
