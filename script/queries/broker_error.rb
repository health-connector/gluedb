# This script looks through transactions that were created by the rake task to update glue that have failed to load in Glue because of a broker error. 
require 'pry'
require 'csv'

transactions = Protocols::X12::TransactionSetEnrollment

err_transmission = []

transactions.each do |transmission|
	if tranmission.error_list.length != 0
		err_transmission.push(transmission)
	end
end

## Create an array of the error_list that can be evaluated.
## Use .split to separate the words in each piece of the error_list array. 
## downcase everything in the .split array 
## use .include?() to see if it has the word broker anywhere. 

broker_error = []

err_transmission.each do |transmission|
	err_list = transmission.error_list
	err_list.each do |err|
		err_each = err.split
		err_each.map!(&:downcase)
		if err_each.include?("broker")
			broker_error.push(transmission)
		end
	end
end

name = nil

def edi_parse(edi)
	parsed = edi.split("~")
	parsed.each do |line|
		if line.include? "nm1"
			name = line
		end
	end
	binding.pry
end

binding.pry

# CSV.open("broker_error.csv", "w") do |csv|
# 	csv << ["id", "aasm_state", "bgn01", "bgn02", "bgn03", "bgn04", "bgn05", "bgn06", "bgn08", "File Name", "Carrier ID", "Employer ID", "Errors", "Policy ID", "Submitted At", "Updated At", "Transaction Type"]
# 	broker_error.each do |trans|
# 		id = trans._id
# 		transmission = Protocols::X12::Transmission.find_by(_id: trans.transmission_id)
# 		aasm_state = trans.aasm_state
# 		bgn01 = trans.bgn01
# 		bgn02 = trans.bgn02
# 		bgn03 = trans.bgn03
# 		bgn04 = trans.bgn04
# 		bgn05 = trans.bgn05
# 		bgn06 = trans.bgn06
# 		bgn08 = trans.bgn08
# 		file_name = transmission.file_name
# 		carrier_id = trans.carrier_id
# 		employer_id = trans.employer_id
# 		errors = trans.error_list
# 		pid = trans.policy_id
# 		submitted_at = trans.submitted_at
# 		updated_at = trans.updated_at
# 		transkind = trans.transaction_kind
# 		raw_edi = trans.body.read
# 		csv << [id, aasm_state, bgn01, bgn02, bgn03, bgn04, bgn05, bgn06, bgn08, file_name, carrier_id, employer_id, errors, pid, submitted_at, updated_at, transkind]
# 	end
# end