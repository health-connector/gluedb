require 'pry'
require 'csv'

start_date = Date.new(2014,12,31)

employers_2014 = Employer.where(:plan_year_start  => { "$lte" => start_date})

puts employers_2014.count

employer_ids = []

employers_2014.each do |emp|
	employer_ids.push(emp._id)
end

policies = Policy.where(:employer_id.in => employer_ids)

puts policies.count

wrong_year = []

count = 0

policies.each do |policy|
	count += 1
	pys2015 = pol.employer.plan_year_start + 1.year
	if pol.enrollees.first.coverage_start < pys2015 and pol.plan.year == 2015
		wrong_year.push(pol)
	end
	if count % 1000 == 0
		puts Time.now
		puts "#{count} iterations performed."
		puts wrong_year.count
		puts " "
	end
end

CSV.open("wrong_plan_year.csv", "w") do |csv|
	csv << ["Enrollment Group ID", "AASM state", "Employer", "Effective Date", "Plan", "Plan Year", "Subscriber", "Subscriber Member ID", "Policy ID"]
	wrong_year.each do |policy|
		eg_id = policy.eg_id
		aasm = policy.aasm_state
		employer = policy.employer.name
		effective_date = policy.enrollees.first.coverage_start
		plan = policy.plan.name
		plan_year = policy.plan.year
		subscriber = policy.enrollees.first.person.name_full
		subscriber_member_id = policy.enrollees.first.m_id
		policy_id = policy._id
		csv << [eg_id, aasm, employer, effective_date, plan, plan_year, subscriber, subscriber_member_id, policy_id]
	end
end