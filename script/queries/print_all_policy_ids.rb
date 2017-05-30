pols_1 = Policy.collection.raw_aggregate([{
  "$group" => {"_id" => "$eg_id"}
}])

pols_2 = Policy.collection.aggregate([{"$group" => {"_id" => "$hbx_enrollment_ids"}}])

pols = []

pols_1.each do |pol|
  pols << pol["_id"]
end

pols_2.each do |pol_ids|
  next if pol_ids["_id"].blank?
  pol_ids["_id"].each do |id|
    pols << id
  end
end

pols.compact.uniq!

pols.each do |pol|
  puts pol
end
