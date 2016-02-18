# This script creates premium payments in glue. 
## It requires a spreadsheet with the following headers. 
### "Paid At"
### "Payment Amount" - this should be in dollars and cents. 
### "Start Date" 
### "End Date"
### "Payment Type" - this is found in the EDI of the payment. 
### "Carrier Abbreviation" - e.g. KFMASI
### "Enrollment Group ID" - Enrollment Group ID of the policy to attach the payment to. 

filename = "" ## supply the filename of your spreadsheet here. 

CSV.foreach(filename, headers: true) do |row|
	begin
		premium_row = row.to_hash 

		## Create the Premium Payment
		new_payment = PremiumPayment.new

		 ## Add the payment date. 
		new_payment.paid_at = premium_row["Paid At"]	

		## Add the payment amount. Fill the blank in with the dollar amount, as glue stores the value in cents. 
		new_payment.pmt_amt = ((premium_row["Payment Amount"].to_d)*(100.to_d)).to_i

		## Add the start and end dates for the premium.
		new_payment.start_date = premium_row["Start Date"]
		new_payment.end_date = premium_row["End Date"]	

		## Add the coverage period. This is a string value, e.g. "20160101-2016131"
		sd = new_payment.start_date.iso8601.gsub("-")
		ed = new_payment.end_date.iso8601.gsub("-")
		new_payment.coverage_period = "#{sd}-#{ed}"

		## Assign the payment type. You can find this in the EDI in all_json.csv. It'll be like RMR**ZZ**____
		new_payment.hbx_payment_type = premium_row["Payment Type"] 	

		## Assign the carrier.
		carrier = Carrier.where(abbrev: premium_row["Carrier Abbreviation"]).first
		new_payment.carrier_id = carrier._id 	

		## Link the premium payment to a policy.
		policy = Policy.where(eg_id: premium_row["Enrollment Group ID"]) 
		new_payment.policy_id = policy._id # Don't put this in quotes. 	

		## Save the payment. 
		new_payment.save
	rescue Exception=>e
		binding.pry
	end
end