@employers = Employer.in(:fein => ['536002522', '536002523', '536002558'])

@employers.to_a.each do |employer|
  plan_year_2016 = employer.plan_year_of(Date.new(2016,01,01))

  if plan_year_2016.nil?
    plan_year_2016 = PlanYear.new(start_date: Date.new(2016,01,01), end_date: Date.new(2016,12,31),
                                  open_enrollment_start: Date.new(2015,11,9), open_enrollment_end: Date.new(2015, 12, 14))
    employer.plan_years << plan_year_2016
  end

  plan_year_2016.elected_plans = []

  if plan_year_2016.elected_plans.blank?
    Plan.where(metal_level:'gold').and(market_type:'shop').each do |plan|
      plan_year_2016.elected_plans << ElectedPlan.new({plan_year: plan_year_2016,
                                                       coverage_type: plan.coverage_type,
                                                       metal_level: plan.metal_level,
                                                       qhp_id: plan.hios_plan_id,
                                                       carrier: plan.carrier,
                                                       plan_name: plan.name,
                                                       hbx_plan_id: plan.hios_plan_id + "-" + plan.year.to_s})
    end
  end

  employer.save!
end