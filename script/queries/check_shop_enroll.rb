require 'pry'
require 'csv'

employer_feins = []

effective_date_check = Date.new(2015,8,1) 

employers = Employer.where(:fein.in => employer_feins)

employer_ids = []

employers.each do |emp|
	employer_ids.push(emp._id)
end

policies = Policy.where(:employer_id.in => employer_ids)

policies2015 = []

policies.each do |pol|
	if pol.plan.year == 2015 and pol.enrollees.first.coverage_start == effective_date_check
		policies2015.push(pol)
	end
end

CSV.open("shop_enrollments_checked.csv", "w") do |csv|
	csv << ["Enrollment Group ID", "AASM state", "Employer", "Effective Date", "Plan", "Subscriber", "Subscriber Member ID", "Policy ID"]
	policies2015.each do |policy|
		eg_id = policy.eg_id
		aasm = policy.aasm_state
		employer = policy.employer.name
		effective_date = policy.enrollees.first.coverage_start
		plan = policy.plan.name
		subscriber = policy.enrollees.first.person.name_full
		subscriber_member_id = policy.enrollees.first.m_id
		policy_id = policy._id
		csv << [eg_id, aasm, employer, effective_date, plan, subscriber, subscriber_member_id, policy_id]
	end
end