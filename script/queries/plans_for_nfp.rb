require 'csv'
all_plans = Plan.all

cache = Caches::MongoidCache.new(Carrier)

CSV.open("plans_for_nfp.csv", "w") do |csv|
  csv << ["id", "carrier", "plan_name", "plan_year", "hios_id", "coverage_type", "metal_level", "renewal_plan_id"]
  all_plans.each do |plan|
    csv << [plan.id, cache.lookup(plan.carrier_id).abbrev, plan.name, plan.year.to_s, plan.hios_plan_id, plan.coverage_type, plan.metal_level, plan.renewal_plan_id] 
  end
end
