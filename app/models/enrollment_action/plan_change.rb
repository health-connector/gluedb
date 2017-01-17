module EnrollmentAction
  class PlanChange < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false if same_plan?(chunk)
      (!carriers_are_different?(chunk)) && !dependents_changed?(chunk)
    end
  end
end
