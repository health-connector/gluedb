module EmployerContributions
  class DistrictOfColumbiaEmployer < Strategy
    belongs_to :reference_plan, :class_name => "Plan"

    field :employee_max_percent, type: BigDecimal
    field :dependent_max_percent, type: BigDecimal
  end
end
