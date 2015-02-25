module Queries
  class PoliciesWithNoFamilies
    def initialize
    end

    def execute
      families = Family.all.to_a.select do |f| !f.active_household.nil? end
      policies_with_hbx_enrollment = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).map(&:policy).compact.uniq
      all_policies = Policy.all
      all_policies - policies_with_hbx_enrollment
    end
  end
end
