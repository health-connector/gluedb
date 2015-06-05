module Queries
  class PoliciesWithNoFamilies
    def initialize
    end

    def execute
      policies_with_hbx_enrollment = Family.all.flat_map(&:active_household).compact.flat_map(&:hbx_enrollments).map(&:policy).uniq
      all_policies = Policy.all
      all_policies - policies_with_hbx_enrollment
    end
  end
end
