require 'pry'
require 'csv'

policy_ids = []

CSV.open("last_transaction.csv", "w")
	csv << ["Policy ID", "Last Transaction"]
	policy_ids.each do |id|
		pol = Policy.find_by(_id: id)
		pid = pol._id
		tbody = pol.edi_transaction_sets.last.body.read
		if tbody.include? "*024*"
			type = "cancel"
		else
			type = "not cancel"
		end
		csv << [pid, type]
	end
end