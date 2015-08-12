require 'pry'
require 'csv'
require 'mongoid'
transactions = Protocols::X12::TransactionSetEnrollment

err_tran = []

transactions.each do |tran|
	if tran.error_list.length != 0
		err_tran.push(tran)
	end
end

CSV.open("error_trans_all.csv", "w") do |csv|
	csv << ["id", "aasm_state", "bgn01", "bgn02", "bgn03", "bgn04", "bgn05", "bgn06", "bgn08", "File Name", "Employer ID", "Errors", "Submitted At", "Updated At", "Transaction Type"]
	err_tran.each do |trans|
		if trans.policy_id == nil 
			id = trans._id
			transmission = Protocols::X12::Transmission.find_by(_id: trans.transmission_id)
			aasm_state = trans.aasm_state
			bgn01 = trans.bgn01
			bgn02 = trans.bgn02
			bgn03 = trans.bgn03
			bgn04 = trans.bgn04
			bgn05 = trans.bgn05
			bgn06 = trans.bgn06
			bgn08 = trans.bgn08
			file_name = transmission.file_name
			carrier_id = trans.carrier_id
			employer_id = trans.employer_id
			errors = trans.error_list
			submitted_at = trans.submitted_at
			updated_at = trans.updated_at
			transaction_kind = trans.transaction_kind
			raw_edi = trans.body.read
			csv << [id, aasm_state, bgn01, bgn02, bgn03, bgn04, bgn05, bgn06, bgn08, file_name, employer_id, errors, submitted_at, updated_at, transaction_kind]
		end
	end
end
