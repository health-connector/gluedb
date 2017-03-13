module EnrollmentAction
  module PlanComparisonHelper
    def same_plan?(chunk)
      chunk.first.existing_plan.id == chunk.last.existing_plan.id
    end

    def carriers_are_different?(chunk)
      chunk.first.existing_plan.carrier_id != chunk.last.existing_plan.carrier_id
    end
  end
end
