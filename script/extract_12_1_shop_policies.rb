active_start = Date.new(2015,11,30)
active_end = Date.new(2016,11,30)
terminated_end = Date.new(2016,11,30)

employer_ids = PlanYear.where(:start_date => {"$gt" => active_start}, :end_date => {"$lte" => active_end}).pluck(:employer_id)

eligible_pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => active_start}
  }}, :employer_id => {"$in" => employer_ids}}).no_timeout

def current_plan_year(employer)
  py_window = Date.new(2016, 11, 30)
  employer.plan_years.detect do |plan_year|
    py_start = plan_year.start_date
    py_end = plan_year.end_date
    date_range = (py_start..py_end)
    date_range.include?(py_window)
  end
end

def in_current_plan_year?(policy,employer)
  plan_year = current_plan_year(employer)
  return false unless plan_year
  policy_start_date = policy.subscriber.coverage_start
  py_start = plan_year.start_date
  py_end = plan_year.end_date
  date_range = (py_start..py_end)
  if date_range.include?(policy_start_date)
    return true
  else
    return false
  end
end

Caches::MongoidCache.allocate(Employer)

enrollment_ids = []

eligible_pols.each do |pol|
  if !pol.canceled?
    if !(pol.subscriber.coverage_start > active_end)
      unless (!pol.subscriber.coverage_end.blank?) && pol.subscriber.coverage_end < terminated_end
        employer = Caches::MongoidCache.lookup(Employer, pol.employer_id) {pol.employer}
        if !in_current_plan_year?(pol,employer)
          next
        end
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
  current_member_record = hash[enrollment.subscriber.person.authority_member_id]
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
  hash[enrollment.subscriber.person.authority_member_id] = filter_superceded_enrollments + [comparison_record]
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
