require 'pry'
require 'csv'

puts "Started At #{Time.now}"

start_date = Time.mktime(2015,10,15,0,0,0)

end_date = Time.mktime(2016,2,29,23,59,59)

transaction_errors = Protocols::X12::TransactionSetEnrollment.where("error_list" => {"$exists" => true, "$not" => {"$size" => 0}},
																	:created_at => {"$gte" => start_date, "$lte" => end_date}).no_timeout
																	
db = Mongoid::Sessions.default
carrier_collection = db[:carriers]

def find_subscriber(policy)
	subscriber = policy.subscriber
	if subscriber == nil
		subscriber = policy.enrollees.select {|enrollee| enrollee.rel_code == "self"}.first
	end
	return subscriber
end

count = 0

def find_carrier_name_by_filename(filename)
	if /GHMSI/.match(filename) != nil
		return "CareFirst"
	elsif /AHI/.match(filename) != nil
		return "Aetna"
	elsif /KFMASI/.match(filename) != nil
		return "Kaiser"
	elsif /UHIC/.match(filename) != nil
		return "United"
	elsif /BLHI/.match(filename) != nil
		return "BestLife"
	elsif /DCHBX/.match(filename) != nil
		return "DC HealthLink"
	elsif /DDPA/.match(filename) != nil
		return "Delta Dental"
	elsif /DTGA/.match(filename) != nil
		return "Dentegra"
	elsif /DMND/.match(filename) != nil
		return "Dominion"
	elsif /GARD/.match(filename) != nil
		return "Guardian"
	elsif /META/.match(filename) != nil
		return "MetLife"
	end
end

carefirst_errors = []
aetna_errors = []
kaiser_errors = []
united_errors = []
bestlife_errors = []
dchl_errors = []
dd_errors = []
dentegra_errors = []
dominion_errors = []
guardian_errors = []
metlife_errors = []
uncat_errors = []

total_transactions = transaction_errors.count.to_d

cat_count = 0

transaction_errors.each do |error|
	cat_count += 1
	if cat_count % 1000 == 0
		puts "#{Time.now} - #{cat_count}"
	end
	carrier_name = error.transmission.sender.try(:name)
	if carrier_name == "CareFirst"
		carefirst_errors.push(error)
	elsif carrier_name == "Aetna"
		aetna_errors.push(error)
	elsif carrier_name == "Kaiser"
		kaiser_errors.push(error)
	elsif carrier_name == "United Health Care"
		united_errors.push(error)
	elsif carrier_name == "BestLife"
		bestlife_errors.push(error)
	elsif carrier_name == "DC HealthLink"
		dchl_errors.push(error)
	elsif carrier_name == "Delta Dental"
		dd_errors.push(error)
	elsif carrier_name == "Dentegra"
		dentegra_errors.push(error)
	elsif carrier_name == "Dominion"
		dominion_errors.push(error)
	elsif carrier_name == "Guardian"
		guardian_errors.push(error)
	elsif carrier_name == "MetLife"
		metlife_errors.push(error)
	else
		uncat_errors.push(error)
	end
end

def parse_edi_for_hbx_id(body)
	transaction_array = body.split(/~/)
	correct_segment = transaction_array.select{|segment| segment.match(/REF\S0F/)}
	if correct_segment.count != 0
		return correct_segment.first.gsub("REF*0F*","")
	else
		return "Not Found in EDI"
	end
end

def parse_edi_for_eg_id(body)
	transaction_array = body.split(/~/)
	correct_segment = transaction_array.select{|segment| segment.match(/REF\S1L/)}
	if correct_segment.count != 0
		return correct_segment.first.gsub("REF*1L*","")
	else
		return "Not Found in EDI"
	end
end

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("transaction_errors_carefirst_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	carefirst_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_aetna_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	aetna_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_kaiser_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	kaiser_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_united_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	united_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_bestlife_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	bestlife_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_dchl_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	dchl_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_delta_dental_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	dd_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_dentegra_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	dentegra_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_dominion_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	dominion_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_guardian_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	guardian_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_metlife_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	metlife_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end

CSV.open("transaction_errors_no_carrier_name_#{timestamp}.csv","w") do |csv|
	csv << ["Carrier","Transaction Kind", "Filename","BGN02","Policy ID","Subscriber HBX ID",
			"Submitted At Date", "Submitted At Time", "Ack/Nack Date", "Ack/Nack Time", "Market",
			"Error Description"]
	uncat_errors.each do |transaction_error|
		count += 1
		if count % 1000 == 0
			puts "#{((count.to_d/total_transactions.to_d)*100.to_d)}% complete."
		end
		begin
			if transaction_error.policy_id != nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				policy = transaction_error.policy
				eg_id = policy.eg_id
				subscriber = find_subscriber(policy)
				subscriber_hbx_id = subscriber.try(:m_id)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
						error_description]
			elsif transaction_error.policy_id == nil
				filename = transaction_error.body.to_s
				carrier_name = find_carrier_name_by_filename(filename)
				transmission = transaction_error.transmission
				transaction_kind = transaction_error.transaction_kind
				error_description = transaction_error.error_list
				bgn02 = transaction_error.bgn02
				edi_body = transaction_error.body.read
				eg_id = parse_edi_for_eg_id(edi_body)
				subscriber_hbx_id = parse_edi_for_hbx_id(edi_body)
				submitted_at_date = transaction_error.submitted_at.strftime("%m-%d-%Y")
				submitted_at_time = transaction_error.submitted_at.strftime("%H:%M:%S")
				market = transmission.gs02
				ack_nack = transaction_error.try(:ack_nak_processed_at)
				if ack_nack != nil
					ack_nack_date = ack_nack.strftime("%m-%d-%Y")
					ack_nack_time = ack_nack.strftime("%H:%M:%S")
				end
				csv << [carrier_name, transaction_kind, filename.gsub("uploads/#{bgn02}_",""), bgn02, eg_id, subscriber_hbx_id,
						submitted_at_date,submitted_at_time,ack_nack_date,ack_nack_time, market,
				 		error_description]
			end
		rescue Exception=>e
			binding.pry
		end
	end
end
