module AssistanceStrategies
  class SetAgnosticBenchmarkPlan < AssistanceStrategy
    belongs_to :benchmark_plan, :class_name => "Plan", :inverse_of => nil

    embeds_many :fpl_percentages
    accepts_nested_attributes_for :fpl_percentages

    field :fpl_amounts, type: Hash
    field :additional_fpl_per_person, type: BigDecimal

    def calculate_assistance(people, income)
      catch(:assistance_calculated) do
        possible_assistance = calculate_benchmark_for(people) - calculate_fpl_responsible_amount(people, income)
        assistance = [0.00, possible_assistance].max
        [:assistance, sprintf("%.2f", assistance).to_f]
      end
    end

    def fpl_income_for(people)
      ppl_count = people.length
      fpl_h = {}
      fpl_amounts.each_pair do |k, v|
        fpl_h[k.to_i] = v
      end
      return fpl_h[ppl_count].to_f if fpl_h.has_key?(ppl_count)
      max_ppl = fpl_h.keys.max
      additional_ppl = ppl_count - max_ppl
      fpl_h[max_ppl].to_f + (additional_ppl.to_f * additional_fpl_per_person.to_f)
    end

    def calculate_fpl_responsible_amount(people, income)
      fpl_percent = income/fpl_income_for(people)
      found_percentage = fpl_percentages.detect { |fplp| fplp.include?(fpl_percent) }
      throw(:assistance_calculated, [:assisted, 0.00]) unless found_percentage
      result = income * found_percentage.percentage(fpl_percent) * 0.083333
      sprintf("%.2f", result).to_f
    end

    def calculate_benchmark_for(people)
      people.inject(0.00) do |acc, person|
        acc + benchmark_plan.rate(start_date, start_date, person.dob).amount.to_f
      end
    end

    def start_date
      @start_date ||= Date.new(fiscal_year.to_i, 1, 1)
    end
  end
end
