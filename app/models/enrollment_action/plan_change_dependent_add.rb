module EnrollmentAction
  class PlanChangeDependentAdd < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper

    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false if same_plan?(chunk)
      (!carriers_are_different?(chunk)) && dependents_added?(chunk)
    end
  end
end
