class FplPercentage
  include Mongoid::Document

  field :min, type: BigDecimal
  field :max, type: BigDecimal
  field :min_contribution, type: BigDecimal
  field :max_contribution, type: BigDecimal

  embedded_in :set_agnostic_benchmark_plan, :class_name => "AssistanceStrategies::SetAgnosticBenchmarkPlan"

  def include?(value)
    (value >= min.to_f) && (value < max.to_f)
  end

  def percentage(value)
    min_contribution.to_f + (
      (
        (value - min) * (max_contribution.to_f - min_contribution.to_f)
      ) / (max.to_f - min.to_f)
    )
  end
end
