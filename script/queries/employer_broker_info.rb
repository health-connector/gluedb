# Returns all the brokers associated with an employer.
require 'csv'

CSV.open("employer_broker_info.csv", "w") do |csv|
	csv << ["Employer Name", "Employer HBX ID", "Employer FEIN","Plan Year Start", "Plan Year End", "Broker Name", "Broker NPN"]
	begin
		PlanYear.all.each do |plan_year|
			employer = plan_year.employer
			employer_name = employer.try(:name)
			employer_hbx_id = employer.try(:hbx_id)
			employer_fein = employer.try(:fein)
			py_start = plan_year.start_date
			py_end = plan_year.end_date
			unless plan_year.broker.blank?
				broker_name = plan_year.broker.try(:name_full)
				broker_npn = plan_year.broker.try(:npn)
			end
			csv << [employer_name, employer_hbx_id, employer_fein, py_start, py_end, broker_name, broker_npn]
		end
	rescue Exception=>e
		puts e.inspect
	end
end