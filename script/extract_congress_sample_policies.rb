active_start = Date.new(2015,12,31)
active_end = Date.new(2016,12,31)
terminated_end = Date.new(2016,10,31)

congress_feins = ["536002558","536002523", "536002522"]
cong_employer_ids = Employer.where(:fein => {"$in" => congress_feins}).map(&:id)

eligible_pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => active_start}
  }}, :employer_id => {"$in" => cong_employer_ids}}).no_timeout

enrollment_ids = []

eligible_pols.each do |pol|
  if !pol.canceled?
    if !(pol.subscriber.coverage_start > active_end)
      unless (!pol.subscriber.coverage_end.blank?) && pol.subscriber.coverage_end < terminated_end
        enrollment_ids << pol.eg_id
      end
    end
  end
end

def reducer(plan_cache, hash, enrollment)
  plan_id = enrollment.plan_id
  plan = plan_cache.lookup(plan_id)
  return hash if plan.nil?
  coverage_kind = plan.coverage_type
  current_member_record = hash[enrollment.subscriber.m_id]
  comparison_record = [
    enrollment.subscriber.coverage_start,
    coverage_kind,
    enrollment.created_at,
    enrollment.employer_id,
    enrollment.eg_id
  ]
  enrollment_count = current_member_record.length
  enrollment_already_superceded = current_member_record.any? do |en|
    ((en[1] == comparison_record[1]) &&
    (en[3] == comparison_record[3]) &&
    (en[0] > comparison_record[0])) ||
    (
      (en[1] == comparison_record[1]) &&
      (en[0] == comparison_record[0]) &&
      (en[3] == comparison_record[3]) &&
      (en[2] > comparison_record[2])
    )
  end
  return hash if enrollment_already_superceded
  filter_superceded_enrollments = current_member_record.reject do |en|
    ((en[1] == comparison_record[1]) &&
     (en[3] == comparison_record[3]) &&
    (en[0] <= comparison_record[0])) ||
    (
      (en[1] == comparison_record[1]) &&
      (en[0] == comparison_record[0]) &&
      (en[3] == comparison_record[3]) &&
      (en[2] < comparison_record[2])
    )
  end
  hash[enrollment.subscriber.m_id] = filter_superceded_enrollments + [comparison_record]
  hash
end

policies_to_compare = Policy.where({:eg_id => {"$in" => enrollment_ids}})

start_hash = Hash.new { |h, key| h[key] = [] }
pc = Caches::PlanCache.new

policies_to_compare.each do |pol|
    reducer(pc, start_hash, pol)
end

results = start_hash.values.flat_map { |v| v.map(&:last) }

results.each do |res|
  puts "localhost/resources/v1/policies/#{res}.xml"
end
