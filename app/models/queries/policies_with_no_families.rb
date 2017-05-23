module Queries
  class PoliciesWithNoFamilies
    def initialize
    end

    # returns ids of policies that do not belong to any family
    def execute
      policies_with_hbx_enrollment = Family.all.flat_map(&:active_household).compact.flat_map(&:hbx_enrollments).map(&:policy_id).uniq
      Policy.where(:id.nin => policies_with_hbx_enrollment).pluck(:id).to_a
    end
  end
end
