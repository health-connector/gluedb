require 'pry'
require 'csv'

policy_ids = []

CSV.open("last_transaction.csv", "w")
	csv << ["Policy ID", "Last Transaction"]
	policy_ids.each do |id|
		policy = Policy.find_by(_id: id)
		policy_id = policy._id
		transmission_body = policy.edi_transaction_sets.last.body.read
		if transmission_body.include? "*024*"
			type = "cancel"
		else
			type = "not cancel"
		end
		csv << [policy_id, type]
	end
end