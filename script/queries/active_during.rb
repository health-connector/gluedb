pols = PolicyStatus::Active.between(Date.new(2013,12,31), Date.new(2014,12,31)).results

puts pols.count
