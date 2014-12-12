require 'csv'

congress_feins = %w{
}

emp_ids = Employer.where(:fein => { "$in" => congress_feins }).map(&:id)

policies = Policy.no_timeout.where(
  PolicyStatus.active_as_of(Date.new(2015, 1, 1),
    {
    :employer_id => { "$in" => emp_ids }
  }
  ).query
)

plan_hash = Plan.all.inject({}) do |acc, p|
  acc[p.id] = p
  acc
end

carrier_hash = Carrier.all.inject({}) do |acc, c|
  acc[c.id] = c
  acc
end

CSV.open("hannah_congress_renewals.csv", 'w') do |csv|
  csv << ["First Name", "Middle Name", "Last Name", "DOB", "SSN", "Employer", "FEIN", "HIOS ID", "Dependents", "Premium Total", "Employer Responsible", "Employee Responsible"]
  policies.each do |pol|
    subscriber = pol.subscriber
    sub_person = subcriber.person
    deps = pol.enrollees.count - 1
    csv << [
      sub_person.name_first,
      sub_person.name_middle,
      sub_person.name_last,
      sub_person.authority_member.dob,
      sub_person.authority_member.ssn,
      pol.employer.name,
      pol.employer.fein,
      pol.plan.hios_plan_id,
      deps,
      pol.pre_tot_amt,
      pol.tot_emp_res_amt,
      pol.tot_res_amt
    ]
  end
end
