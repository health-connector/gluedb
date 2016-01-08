pols = Policy.collection.raw_aggregate([{
  "$group" => {"_id" => "$eg_id"}
}])

pols.each do |pol|
  puts pol["_id"]
end
