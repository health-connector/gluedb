p = Plan.find("")
dupe = Plan.find("")

bad_pols = Policy.where(plan: dupe)

bad_pols.each do |policy|
 policy.plan = p
 policy.save!
end

bad_plans = Plan.where(renewal_plan: dupe)

bad_plans.each do |plan|
 plan.renewal_plan = p
 plan.save!
end

puts bad_policies = Policy.where(plan: dupe).count
puts bad_plans = Plan.where(renewal_plan: dupe).count

dupe.delete