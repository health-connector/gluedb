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

policies.each do |pol|
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
	wrong_year.each do |pol|
		eg_id = pol.eg_id
		aasm = pol.aasm_state
		employer = pol.employer.name
		eff_dt = pol.enrollees.first.coverage_start
		plan = pol.plan.name
		plan_year = pol.plan.year
		subscriber = pol.enrollees.first.person.name_full
		sub_m_id = pol.enrollees.first.m_id
		p_id = pol._id
		csv << [eg_id, aasm, employer, eff_dt, plan, plan_year, subscriber, sub_m_id, p_id]
	end
end