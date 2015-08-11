require 'pry'
require 'csv'

employer_feins = []

eff_dt_check = Date.new(2015,8,1) 

employers = Employer.where(:fein.in => employer_feins)

employer_ids = []

employers.each do |emp|
	employer_ids.push(emp._id)
end

policies = Policy.where(:employer_id.in => employer_ids)

policies2015 = []

policies.each do |pol|
	if pol.plan.year == 2015 and pol.enrollees.first.coverage_start == eff_dt_check
		policies2015.push(pol)
	end
end

CSV.open("shop_enrollments_checked.csv", "w") do |csv|
	csv << ["Enrollment Group ID", "AASM state", "Employer", "Effective Date", "Plan", "Subscriber", "Subscriber Member ID", "Policy ID"]
	policies2015.each do |pol|
		eg_id = pol.eg_id
		aasm = pol.aasm_state
		employer = pol.employer.name
		eff_dt = pol.enrollees.first.coverage_start
		plan = pol.plan.name
		subscriber = pol.enrollees.first.person.name_full
		sub_m_id = pol.enrollees.first.m_id
		p_id = pol._id
		csv << [eg_id, aasm, employer, eff_dt, plan, subscriber, sub_m_id, p_id]
	end
end