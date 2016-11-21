active_policy_results = Policy.collection.raw_aggregate([
 {"$match" => {"employer_id" => {"$ne" => nil}, "enrollees.coverage_start" => {"$gte" => Time.mktime(2015,9,30)}}},
 {"$unwind" => "$enrollees"},
 {"$match" => {"enrollees.rel_code" => "self"}},
 {"$match" => {"$or" => [{"enrollees.coverage_end" => nil}, {"enrollees.coverage_end" => {"$gt" => Time.mktime(2016,9,30)}}]}},
 {"$group" => {"_id" => "$eg_id"}}
])

eg_ids = active_policy_results.map do |rec|
  rec["_id"]
end


results = Policy.collection.raw_aggregate([
 {"$match" => {"eg_id" => {"$in" => eg_ids}}},
 {"$unwind" => "$enrollees"},
 {"$group" => {"_id" => "$enrollees.m_id"}}
])

results.each do |res|
  puts "localhost/resources/v1/individuals/#{res["_id"]}.xml"
end
