require 'csv'

CSV.open("premium_amounts.csv", "w")

plan_year = 2015

plans = Plan.where(:year => plan_year)

CSV.open("premium_amounts.csv", "w") do |csv|
	csv << ["Plan Name", "HIOS ID", "Year", premium.age]
	plans.each do |plan|
		name = plan.name
		hios_id = plan.hios_plan_id
		year = plan.year
		plan.premium_tables.each do |premium|
			prem_amount = premium.amount
			csv << [name, hios_id, year, prem_amount]
		end
	end
end