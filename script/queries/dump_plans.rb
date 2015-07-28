def dump_plan_for_enroll(plan)
  plan_json = {
    :id => plan.id.to_s,
    :name => plan.name,
    :hios_id => plan.hios_plan_id,
    :ehb => plan.ehb,
    :active_year => plan.year,
    :carrier_profile_id => plan.carrier_id.to_s,
    :metal_level => plan.metal_level,
    :coverage_kind => plan.coverage_type,
    :renewal_plan_id => plan.renewal_plan_id.to_s,
    :minimum_age => 19,
    :maximum_age => 66,
    :market => (((plan.ehb == 0) || (plan.coverage_type.downcase == "dental")) ? "shop" : "individual")
  }
  premium_tables = []

  plan.premium_tables.each do |pt|
    if (pt.age < 67) && (pt.age > 18)
      premium_tables << {
        :age => pt.age,
        :start_on => pt.rate_start_date,
        :end_on => pt.rate_end_date,
        :cost => pt.amount
      }
    end
  end
  puts JSON.dump(plan_json.merge({:premium_tables => premium_tables.uniq}))
end

puts "["
Plan.each do |pln|
  dump_plan_for_enroll(pln)
  puts(",")  
end

