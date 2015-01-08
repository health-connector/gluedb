module Collections
  class Policies < Collection
    def covering_health
      items.select { |p| p.coverage_type == 'health'}
    end

    def covering_dental
      items.select { |p| p.coverage_type == 'dental'}
    end

    def currently_active
      items.select { |p| p.currently_active? }
    end

    def future_active
      items.select { |p| p.future_active? }
    end

    def is_or_will_be_active
      items.select { |p| p.currently_active? || p.future_active? }
    end

    def overlaps_policy(policy)
      items.select { |p| policies_overlap?(policy, p) }
    end
    
    def sort_by_start_date
      items.sort_by { |pol| pol.policy_start }
    end

    def most_recent
      self.sort_by_start_date.last
    end

    private

    def policies_overlap?(a, b)
      first, second = Collections::Policies.new([a,b]).sort_by_start_date.to_a
      if first.policy_end.nil?
        return first.coverage_period.overlaps?(second.coverage_period)
      end
      (first.policy_end > second.policy_start)
    end
  end
end
