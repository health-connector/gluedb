## This script generates a list of all policies and (if they exist) their renewal policies. 
## You will need to generate a list of policies with the command RenewalPoliciesFile.new.process inside the rails console. 

require 'csv'
#require 'pry'

unassisted_policies_filename = "renewal_ids_201512201502.txt"

unassisted_policy_ids = []

File.readlines(unassisted_policies_filename).map do |line|
    unassisted_policy_ids.push(line.to_i)
end

CSV.open("unassisted_renewal_policies.csv","w") do |csv|
	csv << ["2015 Policy ID", "2015 Plan Name", "Subscriber HBX ID", "Subscriber Name", "Created On", "Updated On"]
	unassisted_policy_ids.each do |id|
		policy_2015 = Policy.where(_id: id).to_a.first
		created_at = policy_2015.created_at
		updated_at = policy_2015.try(:updated_at)
		coverage_type_2015 = policy_2015.coverage_type
		subscribers = []
		policy_2015.enrollees.each do |enrollee|
			if enrollee.rel_code == "self"
				subscribers.push(enrollee)
			end
		end
		subscriber = subscribers.first
		if subscriber == nil
			csv << [id, "not found", "not found", "not found"]
		else
			subscriber_hbx_id = subscriber.m_id
			subscriber_name = subscriber.person.name_full
			subscriber_policies = subscriber.person.policies.to_a
			plan_name_2015 = policy_2015.plan.name
			policies_2016 = []
			subscriber_policies.each do |policy|
				next if policy.enrollees.first.coverage_start.year != 2016
				next if policy.coverage_type != coverage_type_2015
				policies_2016.push(policy)
			end
			if policies_2016.count == 1
				start_date = policies_2016.first.enrollees.first.coverage_start
				coverage_type = policies_2016.first.coverage_type
				id_2016 = policies_2016.first._id
				plan_name_2016 = policies_2016.first.plan.name
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, updated_at, id_2016, plan_name_2016, coverage_type]
			elsif policies_2016.count == 0
				no_policy = "No 2016 policies."
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, updated_at, no_policy]
			elsif policies_2016.count == 2
				start_date_1 = policies_2016.first.enrollees.first.coverage_start
				coverage_type_1 = policies_2016.first.coverage_type
				id_2016_1 = policies_2016.first._id
				plan_name_2016_1 = policies_2016.first.plan.name
				start_date_2 = policies_2016.first.enrollees.first.coverage_start
				coverage_type_2 = policies_2016.first.coverage_type
				id_2016_2 = policies_2016.first._id
				plan_name_2016_2 = policies_2016.first.plan.name
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, updated_at,
																				id_2016_1,
																				plan_name_2016_1,
																				coverage_type_1,
																				id_2016_2,
																				plan_name_2016_2,
																				coverage_type_2]
			elsif policies_2016.count > 2
				too_many_policies = "More than 2 2016 policies."
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, updated_at, too_many_policies] 
			end
		end
	end
end

