pols = Policy.where("$or" => [
  {:enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)},
    :coverage_end => { "$gt" => Date.new(2015,9,30) }
  }}, :employer_id => nil},
  { :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)},
    :coverage_end => nil
  }}, :employer_id => nil}
])

write_file = File.open("enroll_ind_policies.json", "w")
write_file.puts("[")

member_ids = []

policy_blacklist = [
"200247",
"65835",
"44481",
"49278"
]
count_hash = Hash.new { |hash, key| hash[key] = 0 }

pols.inject(count_hash) do |h, pol|
  h[pol.eg_id] = h[pol.eg_id] + 1
  h
end

sucky_policies = 0

count_hash.each_pair do |k, v|
  if v > 1
    sucky_policies = sucky_policies + 1
    policy_blacklist << k
  end
end

puts sucky_policies

pols.each do |pol|
  if !policy_blacklist.include?(pol.eg_id)
    if !pol.canceled?
      pol.enrollees.each do |en|
        if !en.canceled?
          member_ids << en.m_id
        end
      end
    end
  end
end

member_ids.uniq!

m_cache = Caches::MemberIdPerson.new(member_ids)
people = Person.find_for_members(member_ids)

pols.each do |pol|
  if !pol.canceled?
    if !pol.subscriber.nil?
      sub_id = pol.subscriber.m_id
      sub_person = m_cache.lookup(sub_id)
      if sub_person.authority_member.present?
      ens = pol.enrollees.reject(&:canceled?)
      enrollee_data = ens.map do |en|
        m_person = m_cache.lookup(en.m_id)
        {
          hbx_id: m_person.authority_member.hbx_member_id,
          premium_amount: en.pre_amt,
          coverage_start: en.coverage_start.strftime("%Y%m%d"),
          coverage_end: (en.coverage_end.blank? ? Date.new(2015,12,31) : en.coverage_end).strftime("%Y%m%d")
        }
      end
      data = {
        hbx_id: pol.eg_id,
        plan: {
          hios_id: pol.plan.hios_plan_id,
          active_year: pol.plan.year
        },
        subscriber_id: sub_person.authority_member.hbx_member_id,
        pre_amt_tot: pol.pre_amt_tot,
        tot_res_amount: pol.tot_res_amt,
        applied_aptc: pol.applied_aptc,
        enrollees: enrollee_data
      }
      write_file.print(JSON.dump(data))
      write_file.print(",\n")
      end
    end
  end
end
