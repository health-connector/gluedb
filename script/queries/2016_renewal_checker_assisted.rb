## This script generates a list of all policies and (if they exist) their renewal policies. 
## If doing assisted policies, generate a list of policies with the command RenewalPoliciesFileAssisted.new.process inside the rails console.

require 'csv'
require 'pry'

assisted_policies_filename = "renewal_ids_assisted_201511161832.txt"

assisted_policy_ids = []

File.readlines(assisted_policies_filename).map do |line|
    assisted_policy_ids.push(line.to_i)
end

CSV.open("assisted_renewal_policies.csv","w") do |csv|
	csv << ["2015 Policy ID", "2015 Plan Name", "Subscriber HBX ID", "Subscriber Name", "Created On"]
	assisted_policy_ids.each do |id|
		policy_2015 = Policy.where(_id: id).to_a.first
		created_at = policy_2015.created_at
		subscribers = []
		policy_2015.enrollees.each do |enrollee|
			if enrollee.rel_code == "self"
				subscribers.push(enrollee)
			else
				next
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
				policies_2016.push(policy)
			end
			if policies_2016.count == 1
				start_date = policies_2016.first.enrollees.first.coverage_start
				coverage_type = policies_2016.first.coverage_type
				id_2016 = policies_2016.first._id
				plan_name_2016 = policies_2016.first.plan.name
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, id_2016, plan_name_2016, coverage_type]
			elsif policies_2016.count == 0
				no_policy = "No 2016 policies."
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, no_policy]
			elsif policies_2016.count == 2
				start_date_1 = policies_2016.first.enrollees.first.coverage_start
				coverage_type_1 = policies_2016.first.coverage_type
				id_2016_1 = policies_2016.first._id
				plan_name_2016_1 = policies_2016.first.plan.name
				start_date_2 = policies_2016.first.enrollees.first.coverage_start
				coverage_type_2 = policies_2016.first.coverage_type
				id_2016_2 = policies_2016.first._id
				plan_name_2016_2 = policies_2016.first.plan.name
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, 
																				id_2016_1,
																				plan_name_2016_1,
																				coverage_type_1,
																				id_2016_2,
																				plan_name_2016_2,
																				coverage_type_2]
			elsif policies_2016.count > 2
				too_many_policies = "More than 2 2016 policies."
				csv << [id, plan_name_2015, subscriber_hbx_id, subscriber_name, created_at, too_many_policies] 
			end
		end
	end
end