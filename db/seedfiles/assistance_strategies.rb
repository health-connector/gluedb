fy = 2015

bp_hios = "94506DC0390006-01"

bp = Plan.where(:year => fy, :hios_plan_id => bp_hios).first

assistance_strat = AssistanceStrategies::SetAgnosticBenchmarkPlan.new(
  :fiscal_year => fy,
  :benchmark_plan => bp,
  :medicaid_threshold => 1.33,
  :additional_fpl_per_person => "4060.00",
  :fpl_percentages => [
    {
      :min => 0.00,
      :max => 1.33,
      :min_contribution => 0.0201,
      :max_contribution => 0.0201
    },
    {
      :min => 1.33,
      :max => 1.50,
      :min_contribution => 0.0302,
      :max_contribution => 0.0402
    },
    {
      :min => 1.50,
      :max => 2.00,
      :min_contribution => 0.0402,
      :max_contribution => 0.0634
    },
    {
      :min => 2.00,
      :max => 2.50,
      :min_contribution => 0.0634,
      :max_contribution => 0.0810
    },
    {
      :min => 2.50,
      :max => 3.00,
      :min_contribution => 0.0810,
      :min_contribution => 0.0956
    },
    {
      :min => 3.00,
      :max => 4.00,
      :min_contribution => 0.0956,
      :max_contribution => 0.0956
    }
  ],
  :fpl_amounts => {
    1 => "11670.00",
    2 => "15730.00",
    3 => "19790.00",
    4 => "23850.00",
    5 => "27910.00",
    6 => "31970.00",
    7 => "36030.00",
    8 => "40090.00"
  }
)

assistance_strat.save!
