ct_cache = Caches::Mongoid::SinglePropertyLookup.new(Plan, "coverage_type")
renewal_cache = Caches::Mongoid::SinglePropertyLookup.new(Plan, "renewal_plan_id")
hios_cache = Caches::Mongoid::SinglePropertyLookup.new(Plan, "hios_plan_id")

p_repo = {}

carriers = Carrier.where(:abbrev => "GHMSI").first
plan_ids = Plan.where(:carrier_id => carriers.id).map(&:id)


p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])
p_map.each do |val|
    p_repo[val["member_id"]] = val["person_id"]
end

# No cancels/terms in this batch!
pols_2015 = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)},
    :coverage_end => nil
  }}, :plan_id => {"$in" => plan_ids}, :employer_id => {"$ne" => nil}})

puts pols_2015.length

# Includes terminations!
pols_2014 = Policy.where(PolicyStatus::Active.as_of(Date.new(2014, 12, 31)).query).where({:plan_id => {"$in" => plan_ids}, :employer_id => {"$ne" => nil}})

puts pols_2014.length

# Renewal means they are active and NON-TERMINATED as of 12/31 AND have a ACTIVE 2015 enrollment.

def is_health?(pol2015, ct_cache)
  ct = ct_cache[pol2015.plan_id]
  ct == "health"
end

def is_health_renewal?(pol2015, p_cache, ct_cache, subscribers_from_2014)
  sub_person_id = p_cache[pol2015.subscriber.m_id]
  ct = ct_cache[pol2015.plan_id]
  return false unless ct == "health"
  subscribers_from_2014.include?(sub_person_id)
end

def is_same_plan?(pol2015, p_cache, r_cache, plan_selected_in_2014_for_subscriber, h_cache)
  sub_person_id = p_cache[pol2015.subscriber.m_id]
  plan_2014 = plan_selected_in_2014_for_subscriber[sub_person_id]
  renewal_plan = r_cache[plan_2014]
  hios_2015 = h_cache[pol2015.plan_id].split("-").first
  hios_2014= h_cache[plan_2014].split("-").first
  hios_2015 == hios_2014
end

renewals = []
active_renewals = []
passive_renewals = []
same_plan_renewals = []
different_plan_renewals = []

subs_from_2014 = []
sub_plans_for_2014 = {}

active_2014_health = []
enrollee_amount_2014 = 0

pols_2014.each do |p|
  sub = p.subscriber
  if sub.coverage_end.blank?
    ct = ct_cache[p.plan_id]
    if (ct == "health")
      enrollee_amount_2014 += p.enrollees.length
      active_2014_health << p.id
      person_id = p_repo[sub.m_id]
      subs_from_2014 << person_id
      sub_plans_for_2014[person_id] = p.plan_id
    end
  end
end

puts "2014 Health Policies: #{active_2014_health.length}"

health_renewals = []
enrollee_amount_2015 = 0

health_2015 = []
dental_2015 = []
new_enrollments = []

pols_2015.each do |pol|
  if is_health_renewal?(pol, p_repo, ct_cache, subs_from_2014)
    health_renewals << pol.id
    enrollee_amount_2015 += 1
    renewals << pol.id
    if is_same_plan?(pol, p_repo, renewal_cache, sub_plans_for_2014, hios_cache)
      same_plan_renewals << pol.id
    else
      different_plan_renewals << pol.id
    end
  else
    new_enrollments << pol.id
  end
  if is_health?(pol, ct_cache)
    health_2015 << pol.id
  else
    dental_2015 << pol.id
  end
end

puts "2015 Health Policies: #{health_2015.length}"
puts "2015 Dental Policies #{dental_2015.length}"
puts "New Enrollments: #{new_enrollments.length}"
puts "Renewals: #{renewals.length}"
puts "Renewal - Same Plan: #{same_plan_renewals.length}"
puts "Renewal - Different Plan: #{different_plan_renewals.length}"
