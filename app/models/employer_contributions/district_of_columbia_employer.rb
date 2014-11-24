module EmployerContributions
  class DistrictOfColumbiaEmployer < Strategy
    belongs_to :reference_plan, :class_name => "Plan"

    field :employee_max_percent, type: BigDecimal
    field :dependent_max_percent, type: BigDecimal

    validates_presence_of :employee_max_percent
    validates_presence_of :dependent_max_percent

    def contribution_for(enrollment)
      enrollment.enrollee.inject(0.00) do |total, en|
        total += employer_contribution_for(en)
      end
    end

    def employer_contribution_for(enrollee)
      [reference_contribution_for(enrollee), enrollee.pre_amt].min
    end

    def reference_contribution_for(enrollee)
      reference_percent = enrollee.subscriber? ? employee_max_percent : dependent_max_percent
      enrollee.reference_premium_for(reference_plan, plan_year.start_date) * reference_percent * 0.01
    end
  end
end
