class FplPercentage
  include Mongoid::Document

  field :min, type: BigDecimal
  field :max, type: BigDecimal
  field :min_inclusive, type: Boolean
  field :max_inclusive, type: Boolean
  field :min_contribution, type: BigDecimal
  field :coefficient, type: BigDecimal
  field :divisor, type: BigDecimal

  embedded_in :set_agnostic_benchmark_plan, :class_name => "AssistanceStrategies::SetAgnosticBenchmarkPlan"

  def include?(value)
    upper_comp = max_inclusive ? :<= : :<
    lower_comp = min_inclusive ? :>= : :>
    value.send(lower_comp, min) && value.send(upper_comp, max)
  end

  def percentage(value)
    min_contribution + 
      (coefficient *
       (value - min)/divisor
      )
  end
end
