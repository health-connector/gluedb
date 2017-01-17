module EnrollmentAction
  class DependentDrop < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_dropped?(chunk)
    end
  end
end
