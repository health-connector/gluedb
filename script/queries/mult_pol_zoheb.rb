require 'pry'
require 'csv'

pol = Policy.all.to_a
puts pol.length

CSV.open("multiple_policies_zoheb.csv", "w") do |csv|
	csv << ["Policy ID", "Enrollment Group ID", "AASM State", "HBX ID", "First Name", "Last Name", "SSN", "DOB", "Plan HIOS", "Plan Name"]
	pol.each do |policy|
		policy.enrollees.each do |enrollee|
			if enrollee.coverage_status == "active"
				plan = Plan.find(policy.plan_id)
				if plan.year == 2015
					policy_id = policy._id
					egid = policy.eg_id
					aasm = policy.aasm_state
					person = enrollee.person
					hbxid = enrollee.m_id
					fname = person.name_first
					lname = person.name_last
					ssn = enrollee.member.ssn
					dob = enrollee.member.dob
					hios = plan.hios_plan_id
					plan_name = plan.name
					csv << [policy_id, egid, aasm, hbxid, fname, lname, ssn, dob, hios, plan_name]
				end
			end
		end
	end
end