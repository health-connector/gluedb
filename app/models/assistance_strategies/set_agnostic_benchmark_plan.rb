module AssistanceStrategies
  class SetAgnosticBenchmarkPlan < AssistanceStrategy
    belongs_to :benchmark_plan, :class_name => "Plan", :inverse_of => nil

    def calculate_assistance(people, income)
      [:assistance, 0.00]
    end
  end
end
