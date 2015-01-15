plans = Plan.where({:metal_level => {"$not" => /catastrophic/i}, :coverage_type => /health/i}).map(&:id)

p_repo = {}

p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])

p_map.each do |val|
    p_repo[val["member_id"]] = val["person_id"]
end

pols = PolicyStatus::Active.between(Date.new(2013,12,31), Date.new(2014,12,31)).results.where({
  :plan_id => {"$in" => plans}, :employer_id => nil
}).group_by { |p| p_repo[p.subscriber.m_id] }

puts pols.keys.length
