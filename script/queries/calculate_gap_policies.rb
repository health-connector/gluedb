pols = Policy.where(PolicyStatus::Active.as_of(Date.parse("12/31/2014")).query).where({:employer_id => nil})
m_pols = Policy.where(PolicyStatus::Active.as_of(Date.parse("12/31/2014")).query).where({:employer_id => nil})

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
    :coverage_start => {"$gt" => Date.new(2014,12,31)},
    :coverage_end => nil
  }}})

next_year_pols.each do |pol|
  ct = ct_cache.lookup(pol.plan_id)
  sub_person = p_repo[pol.subscriber.m_id]
  if pol.subscriber.coverage_end.blank?
    excluded_people << "#{sub_person}-----#{ct}"
  end
end


excluded_people.uniq!
m_ids = []

m_pols.each do |pol|
  if pol.subscriber.coverage_end.blank?
    pol.enrollees.each do |en|
      m_ids << en.m_id
    end
  end
end

puts "Populating member cache"
p_obj_repo = Caches::MemberIdPerson.new(m_ids)
member_repo = Caches::MemberCache.new(m_ids)

puts "Populating plan cache"
Caches::MongoidCache.allocate(Plan)

puts "Populating carrier cache"
Caches::MongoidCache.allocate(Carrier)

p_id = 185000

gap_pols = []

pols.each do |pol|
  if pol.subscriber.coverage_end.blank?
    if !pol.subscriber.coverage_start.blank?
#      plan = Caches::MongoidCache.lookup(Plan, pol.plan_id) { pol.plan }
      plan_ct = ct_cache[pol.plan_id]
      sub_person = p_obj_repo.lookup(pol.subscriber.m_id)
      if (!sub_person.authority_member.blank?)
        if (sub_person.authority_member.hbx_member_id == pol.subscriber.m_id)
          if (!excluded_people.include?("#{sub_person.id}-----#{plan_ct}"))
            gap_pols << pol.id
            puts gap_pols.length
            begin
              r_pol = pol.clone_for_renewal(Date.new(2015,1,1))
              r_pol.applied_aptc = pol.applied_aptc
              pc = Premiums::PolicyCalculator.new
              pc.apply_calculations(r_pol)
              p_id = p_id + 1
              out_file = File.open("renewals/#{p_id}.xml", 'w')
              member_ids = r_pol.enrollees.map(&:m_id)
              r_pol.eg_id = p_id.to_s
              ms = CanonicalVocabulary::MaintenanceSerializer.new(r_pol,"change", "renewal", member_ids, member_ids, {:member_repo => member_repo})
              out_file.print(ms.serialize)
              out_file.close
            rescue
              raise([sub_person.id, pol.id].inspect)
            end
          end
        end
      end
    end
  end
end

puts gap_pols.length
