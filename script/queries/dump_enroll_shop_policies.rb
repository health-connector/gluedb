clone_start_date = Date.new(2014,9,30)
year_start_date = Date.new(2014,12,31)
plan_years_2014 = PlanYear.where(:start_date => { "$gt" => clone_start_date, "$lt" => year_start_date})

plan_years_2015 = PlanYear.where(:start_date => { "$gt" => year_start_date})

employer_ids_2014 = []

plan_years_2014.each do |py|
  employer_ids_2014 << py.employer_id
end

employer_ids_2015 = []

plan_years_2015.each do |py|
  employer_ids_2015 << py.employer_id
end

no_congress = Employer.where(:fein => {
  "$in" => []
}).map(&:id)

employer_ids_2014 = employer_ids_2014 - employer_ids_2015
employer_ids_2015 = employer_ids_2015 - no_congress

pols = Policy.where("$or" => [
  { :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)},
    :coverage_end => nil
  }}, :employer_id => {"$in" => employer_ids_2015}},
  {:enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)},
    :coverage_end => { "$gt" => Date.new(2015,10,31) }
  }}, :employer_id => {"$in" => employer_ids_2015}},
  {:enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,9,30)},
    :coverage_end => { "$gt" => Date.new(2015,10,31) }
  }}, :employer_id => {"$in" => employer_ids_2014}},
  { :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,9,30)},
    :coverage_end => nil
  }}, :employer_id => {"$in" => employer_ids_2014}}
])

puts pols.count

write_file = File.open("enroll_shop_policies.json", "w")
write_file.puts("[")

member_ids = []

policy_blacklist = [
"200247",
"65835",
"44481",
"49278"
]
=begin
count_hash = Hash.new { |hash, key| hash[key] = 0 }

pols.inject(count_hash) do |h, pol|
  h[pol.eg_id] = h[pol.eg_id] + 1
  h
end

sucky_policies = 0

count_hash.each_pair do |k, v|
  if v > 1
    sucky_policies = sucky_policies + 1
  end
end

puts sucky_policies
=end

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
          coverage_end: (en.coverage_end.blank? ? nil : en.coverage_end.strftime("%Y%m%d"))
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
        employer_contribution: pol.tot_emp_res_amt,
        enrollees: enrollee_data,
        employer_fein: pol.employer.fein
      }
      write_file.print(JSON.dump(data))
      write_file.print(",\n")
      end
    end
  end
end
