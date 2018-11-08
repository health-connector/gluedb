module EnrollmentAction
  module PlanComparisonHelper
    def same_plan?(chunk)
      chunk.first.existing_plan.id == chunk.last.existing_plan.id
    end

    def carriers_are_different?(chunk)
      chunk.first.existing_plan.carrier_id != chunk.last.existing_plan.carrier_id
    end

    def carrier_requires_simple_plan_changes?(chunk)
      chunk.first.existing_plan.carrier.requires_simple_plan_changes?
    end
  end
end
