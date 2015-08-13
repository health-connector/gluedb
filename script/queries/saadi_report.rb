require 'csv'

# dental_plan_ids = Plan.where({"coverage_type" => "dental"}).map(&:id).map { |tid| Moped::BSON::ObjectId.from_string(tid) }

policies = Policy.no_timeout.where(
  {"eg_id" => {"$not" => /DC0.{32}/}}
)

def bad_eg_id(eg_id)
 (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

plan_hash = Plan.all.inject({}) do |acc, p|
  acc[p.id] = p
  acc
end

carrier_hash = Carrier.all.inject({}) do |acc, c|
  acc[c.id] = c
  acc
end

employer_hash = Employer.all.inject({}) do |acc, e|
  acc[e.id] = e.name
  acc
end

CSV.open("saadi_report.csv", 'w') do |csv|
  csv << ["Enrollment Group ID", "Status", "Authority", "Policy ID", "Number of Transactions", "Sponsor", "Premium Total", "Contribution/APTC", "Total Responsible", "Coverage Type", "Plan HIOS ID", "Plan Name", "Carrier Name", "HBX Id", "Subscriber", "First", "Middle", "Last", "DOB", "SSN", "Start", "End"]
  policies.each_slice(25) do |pols|
    used_policies = pols.reject { |pl| bad_eg_id(pl) }
    member_ids = pols.map(&:enrollees).flatten.map(&:m_id)
    people = Person.where({
      "members.hbx_member_id" => {"$in" => member_ids }
    })
    members_map = people.inject({}) do |acc, p|
      p.members.each do |m|
        acc[m.hbx_member_id] = [m, p]
      end
      acc
    end
    used_policies.each do |pol|
      plan = plan_hash[pol.plan_id]
      carrier = carrier_hash[plan.carrier_id]
      sponsor = pol.employer.blank? ? "Individual" : employer_hash[pol.employer_id]
      csv_transactions = pol.csv_transactions.count
      other_transactions = pol.transaction_set_enrollments.count
      all_transactions = csv_transactions + other_transactions
      pol.enrollees.each do |en|
        member = members_map[en.m_id].first
        per = members_map[en.m_id].last
        pol.is_shop? ? contribution = pol.employer_contribution : contribution = pol.applied_aptc
        pol.is_shop? ? sponsor = pol.employer.name : sponsor = "IVL"
        csv << [pol.eg_id, pol.aasm_state, member.authority?, pol._id, sponsor, all_transactions, pol.total_premium_amount,contribution,pol.total_responsible_amount,plan.coverage_type ,plan.hios_plan_id, plan.name, carrier.name, en.m_id, en.subscriber?, per.name_first, per.name_middle, per.name_last, member.dob.strftime("%Y%m%d"), member.ssn, en.coverage_start.strftime("%m-%d-%Y"), (en.coverage_end.strftime("%m-%d-%Y") unless en.coverage_end.blank?)]
      end
    end
  end
end

