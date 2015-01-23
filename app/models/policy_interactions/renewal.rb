module PolicyInteractions
  class Renewal
    def qualifies?(old_policies, new_policy)
      return false if old_policies.empty?
      return false if (old_policies.any? { |op| new_policy.coverage_period.overlaps?(op.coverage_period) })
      to_check_for_previous = old_policies.select do |op|
        (op.coverage_period.end == new_policy.coverage_period.begin - 1.day) &&
          !op.terminated? &&
          op.carrier_id == new_policy.carrier_id
      end
      return true if to_check_for_previous.any?
      false
    end
  end
end
