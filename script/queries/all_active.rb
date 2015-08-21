require 'csv'

all_cancelled = Policy.collection.raw_aggregate([
  {
    "$unwind" => "$enrollees"
  },
  {"$project" => { "is_cancelled" => {"$eq" => ["$enrollees.coverage_start", "$enrollees.coverage_end"] }, "_id" => 1 , "enrollees.rel_code" => 1} },
  {"$match" => {"is_cancelled" => true, "enrollees.rel_code" => "self" }}
])

puts "Cancelled Policies: #{all_cancelled.count}"

cancelled_ids = all_cancelled.map do |ac|
  ac["_id"]
end

all_m_ids = Person.collection.raw_aggregate([
  {
    "$unwind" => "$members"
  },
  {"$project" => { "is_authority" => {"$eq" => ["$members.hbx_member_id", "$authority_member_id"] }, "members.hbx_member_id" => 1 } },
  {"$match" => {"is_authority" => true}}
])

all_authority_ids = all_m_ids.map do |mid|
  mid["members"]["hbx_member_id"]
end

active_policies = Policy.where(:id => {"$nin" => cancelled_ids}, "enrollees.m_id" => {"$in" => all_authority_ids})

m_cache_ids = Policy.collection.raw_aggregate([
  {
    "$unwind" => "$enrollees"
  },
  {"$project" => { "is_cancelled" => {"$eq" => ["$enrollees.coverage_start", "$enrollees.coverage_end"] }, "enrollees.m_id" => 1 , "enrollees.rel_code" => 1} },
  {"$match" => {"is_cancelled" => true, "enrollees.rel_code" => "self" }}
])

active_policy_count = active_policies.count

m_ids = []
active_policies.each do |m_pol|
  if !m_pol.subscriber.nil?
    m_ids << m_pol.subscriber.m_id
  end
end

m_ids.uniq!


puts "Precaching members"
member_cache = Caches::MemberIdPerson.new(m_ids)
puts "Members precached."

plan_hash = Plan.all.inject({}) do |acc, p|
  acc[p.id] = p
  acc
end

puts "Active Policies: #{active_policy_count}"

counter = 0

m_cache = Hash.new do |h, k|
  h[k] = Person.where({
    "members.hbx_member_id" => k
  }).first
end

pb = ProgressBar.create(
  :title => "Dumping policies",
  :total => active_policy_count,
  :format => "%t %a %e |%B| %P%%"
)

def csv_date_format(d)
  return nil if d.blank?
  d.strftime("%Y-%m-%d")
end

CSV.open("active_policies.csv", "wb") do |csv|
  csv << [
    "enrollment_group_id",
    "market",
    "hios_id",
    "plan_year",
    "plan_name",
    "ehb_percentage",
    "totalcost",
    "applied_aptc",
    "employer_contribution",
    "responsible_amount", 
    "coverage_startdate",
    "coverage_enddate",
    "subscriber_hbx_id", 
    "subscriber_firstname",
    "subscriber_lastname",
    "subscriber_ssn",
    "subscriber_dob",
    "subscriber_gender",
    "metal_level"
  ]
  active_policies.each do |ap|
    if !ap.subscriber.nil?
      subscriber = ap.subscriber
      sub_person = member_cache.lookup(subscriber.m_id)
      plan = plan_hash[ap.plan_id]
      if !sub_person.authority_member.nil?
        csv << [
          ap.enrollment_group_id,
          ap.market,
          plan.hios_plan_id,
          plan.year.to_s,
          plan.name,
          plan.ehb,
          ap.pre_amt_tot,
          ap.applied_aptc,
          ap.tot_emp_res_amt,
          ap.tot_res_amt,
          csv_date_format(subscriber.coverage_start),
          csv_date_format(subscriber.coverage_end),
          sub_person.authority_member_id,
          sub_person.name_first,
          sub_person.name_last,
          sub_person.authority_member.ssn,
          csv_date_format(sub_person.authority_member.dob),
          sub_person.authority_member.gender,
          plan.metal_level
        ]
      end
    end
    pb.increment
  end
end
