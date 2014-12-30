require 'csv'

pols = Policy.where(PolicyStatus::Active.as_of(Date.parse("12/31/2014")).query).where({:employer_id => nil})

p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])

p_repo = {}

ct_cache = Caches::Mongoid::SinglePropertyLookup.new(Plan, "coverage_type")

p_map.each do |val|
  p_repo[val["member_id"]] = val["person_id"]
end

excluded_people = []

next_year_pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)}
  }}})

next_year_pols.each do |pol|
  ct = ct_cache.lookup(pol.plan_id)
  sub_person = p_repo[pol.subscriber.m_id]
  if pol.subscriber.coverage_end.blank?
    excluded_people << [sub_person, ct]
  end
end


excluded_people.uniq!
gap_policies = []

pols.each do |pol|
  if pol.subscriber.coverage_end.blank?
    if !pol.subscriber.coverage_start.blank?
      ct = ct_cache.lookup(pol.plan_id)
      sub_person = p_repo[pol.subscriber.m_id]
      begin
        if (!excluded_people.include?([sub_person, ct]))
          if (pol.subscriber.coverage_start > Date.new(2014,11,30))
            gap_policies << pol.id
          end
        end
      rescue
        raise([sub_person.id, pol.id].inspect)
      end
    end
  end
end

puts gap_policies.length
