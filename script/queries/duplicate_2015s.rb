require 'csv'
p_repo = {}

p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])

ct_cache = Caches::Mongoid::SinglePropertyLookup.new(Plan, "coverage_type")

p_map.each do |val|
  p_repo[val["member_id"]] = val["person_id"]
end

next_year_pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)},
    :coverage_end => nil
  }}})

p_count = Hash.new 

next_year_pols.each do |pol|
  ct = ct_cache.lookup(pol.plan_id)
  p_id = p_repo[pol.subscriber.m_id]
  if !p_count.has_key?(p_id)
    p_count[p_id] = {:health => 0, :dental => 0 , :healths => [], :dentals =>[], :health_policies => [], :dental_policies => []} 
  end
  p_count[p_id][ct.to_sym] = p_count[p_id][ct.to_sym] + 1
  p_count[p_id][(ct + "s").to_sym] = p_count[p_id][(ct + "s").to_sym].push(pol.plan_id).uniq
  p_count[p_id][(ct + "_policies").to_sym] = p_count[p_id][(ct + "_policies").to_sym] + [pol.id]
end

duplicate_dentals = []
duplicate_healths = []

dupes = p_count.select do |k,v|
  selected = false
  if (v[:health] > 1)
    if v[:healths].length == 1
      duplicate_healths << [k, v[:healths], v[:health_policies]]
      selected = true
    end
  end
  if (v[:dental] > 1)
    if v[:dentals].length == 1
      duplicate_dentals << [k, v[:dentals], v[:dental_policies]]
      selected = true
    end
  end
  selected
end

puts duplicate_dentals.length
puts duplicate_healths.length

puts duplicate_dentals.inspect

puts dupes.keys.length
=begin
CSV.open("people_with_duplicate_2015s.csv", "w") do |csv|
  csv << ["HBX ID", "First", "Last", "DOB", "SSN", "Health Policies", "Dental Policies"]
  dupes.each do |k, v|
    per = Person.find(k)
    auth_mem = per.authority_member
    csv << [auth_mem.hbx_member_id, per.name_first, per.name_last, auth_mem.dob.strftime("%Y-%m-%d"), auth_mem.ssn, v[:health], v[:dental]]
  end
end
=end
