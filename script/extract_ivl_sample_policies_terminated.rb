policy_agg = Policy.collection.raw_aggregate([
 {"$match" => {"employer_id" => nil, "enrollees.coverage_start" => {"$gte" => Time.mktime(2015,12,31)}}},
 {"$unwind" => "$enrollees"},
 {"$match" => {"enrollees.rel_code" => "self"}},
 {"$match" => {"enrollees.coverage_start" => {"$lt" => Time.mktime(2017,1,1)}}},
# {"$match" => {"$or" => [{"enrollees.coverage_end" => nil}, {"enrollees.coverage_end" => {"$gt" => Time.mktime(2016,12,31)}}]}},
 {"$group" => {"_id" => "$eg_id"}}
])

pol_ids = policy_agg.map do |pen|
  pen["_id"]
end

policies = Policy.where({"eg_id" => {"$in" => pol_ids}})

def reducer(plan_cache, hash, enrollment)
  plan_id = enrollment.plan_id
  plan = plan_cache.lookup(plan_id)
  raise enrollment.eg_id.inspect if plan.nil?
  return hash if plan.nil?
  coverage_kind = plan.coverage_type
  current_member_record = hash[enrollment.subscriber.person.authority_member_id]
  comparison_record = [
    enrollment.subscriber.coverage_start,
    coverage_kind,
    enrollment.created_at,
    enrollment.eg_id,
    enrollment.terminated? || enrollment.canceled?
  ]
  enrollment_count = current_member_record.length
  enrollment_already_superceded = current_member_record.any? do |en|
    ((en[1] == comparison_record[1]) &&
    (en[0] > comparison_record[0])) ||
    (
      (en[1] == comparison_record[1]) &&
      (en[0] == comparison_record[0]) &&
      (en[2] > comparison_record[2])
    )
  end
  return hash if enrollment_already_superceded
  filter_superceded_enrollments = current_member_record.reject do |en|
    ((en[1] == comparison_record[1]) &&
    (en[0] < comparison_record[0])) || 
    (
      (en[1] == comparison_record[1]) &&
      (en[0] == comparison_record[0]) &&
      (en[2] < comparison_record[2])
    )
  end
  hash[enrollment.subscriber.person.authority_member_id] = filter_superceded_enrollments + [comparison_record]
  hash
end

start_hash = Hash.new { |h, key| h[key] = Array.new } 
pc = Caches::PlanCache.new

policies.inject(start_hash) do |acc, pol|
  reducer(pc, acc, pol)
end

results = start_hash.values.flat_map { |v| v }.select { |en| en.last }.map { |a| a[3] }

results.each do |res|
  puts "localhost/resources/v1/policies/#{res}.xml"
end
