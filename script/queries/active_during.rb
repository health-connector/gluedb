plans = Plan.where({:metal_level => {"$not" => /catastrophic/i}, :coverage_type => /health/i}).map(&:id)

pols = PolicyStatus::Active.between(Date.new(2013,12,31), Date.new(2014,12,31)).results.where({
  :plan_id => {"$in" => plans}, :employer_id => nil
})

puts pols.count
