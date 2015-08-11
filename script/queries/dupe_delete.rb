p = Plan.find("5453a477791e4bd8c1000001")
dupe = Plan.find("5453a543791e4bcd33000001")

bad_pols = Policy.where(plan: dupe)

bad_pols.each do |pol|
 pol.plan = p
 pol.save!
end

bad_plans = Plan.where(renewal_plan: dupe)

bad_plans.each do |plan|
 plan.renewal_plan = p
 plan.save!
end

puts bad_pols = Policy.where(plan: dupe).count
puts bad_plans = Plan.where(renewal_plan: dupe).count

dupe.delete