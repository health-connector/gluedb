require 'pry'
require 'csv'

pol = Policy.all.to_a
puts pol.length

CSV.open("multiple_policies_zoheb.csv", "w") do |csv|
	csv << ["Policy ID", "Enrollment Group ID", "AASM State", "HBX ID", "First Name", "Last Name", "SSN", "DOB", "Plan HIOS", "Plan Name"]
	pol.each do |policy|
		policy.enrollees.each do |enr|
			if enr.coverage_status == "active"
				plan = Plan.find(policy.plan_id)
				if plan.year == 2015
					pid = policy._id
					egid = policy.eg_id
					aasm = policy.aasm_state
					per = enr.person
					hbxid = enr.m_id
					fname = per.name_first
					lname = per.name_last
					ssn = enr.member.ssn
					dob = enr.member.dob
					hios = plan.hios_plan_id
					plan_name = plan.name
					csv << [pid, egid, aasm, hbxid, fname, lname, ssn, dob, hios, plan_name]
				end
			end
		end
	end
end