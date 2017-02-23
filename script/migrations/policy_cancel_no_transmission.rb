## Cancels policies without transmitting a file. 
require 'csv'

filename = 'cf_ivl_passive renewal silent cancels.csv'

enrollment_group_ids = []

policy_ids = []

CSV.foreach(filename, headers: true) do |row|
	policy_ids << row["Policy ID"]
end

policies_to_cancel_by_eg_id = Policy.where(:eg_id => {"$in" => enrollment_group_ids})

policies_to_cancel_by_policy_id = Policy.where(:id => {"$in" => policy_ids})

policies_to_cancel = (policies_to_cancel_by_eg_id + policies_to_cancel_by_policy_id).uniq

policies_to_cancel.each do |policy|
	initial_state = policy.aasm_state.to_s
	subscriber_name = policy.subscriber.person.full_name
	policy.aasm_state = "canceled"
	policy.enrollees.each do |enrollee|
		enrollee.coverage_end = enrollee.coverage_start
		enrollee.emp_stat = "terminated"
		enrollee.coverage_status = "inactive"
		enrollee.save
	end
	policy.save
	if policy.save == true
		puts "#{policy.eg_id} - #{initial_state} - #{subscriber_name} => #{policy.aasm_state} --------- succeeded."
	else
		puts "#{policy.eg_id} - #{initial_state} - #{subscriber_name} => #{policy.aasm_state} --------- failed."
	end
end