module EnrollmentAction
  class DependentAdd < Base
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_added?(chunk)
    end

    def self.dependents_added?(chunk)
    end

    def self.same_plan?(chunk)
    end

    def replace_existing_member_starts
    end

    def mark_only_additions_as_changed
    end

    def replace_policy_id
    end

    def mark_terminations_as_silent
    end
  end
end
