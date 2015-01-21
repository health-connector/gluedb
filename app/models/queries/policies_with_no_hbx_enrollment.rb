module Queries
  class PoliciesWithNoHbxEnrollments
    def initialize
    end

    def execute
      policies_with_hbx_enrollment = HbxEnrollment.all.flat_map(&:policy).compact.uniq
      all_policies = Policy.all
      all_policies - policies_with_hbx_enrollment
    end
  end
end
