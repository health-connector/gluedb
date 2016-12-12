## This script is a very simple script to merge multiple people together.

hbx_id_keep = ""

hbx_id_delete = ""

person_to_keep = Person.where("members.hbx_member_id" => hbx_id_keep).first
person_to_delete = Person.where("members.hbx_member_id" => hbx_id_delete).first

member_to_move = person_to_delete.members.detect {|member| member.hbx_member_id == hbx_id_delete}

## Move the member
person_to_keep.members.push(member_to_move)

## Move any contact information
### address
keep_addresses = person_to_keep.addresses
delete_addresses = person_to_delete.addresses

if keep_addresses.size == 0 && delete_addresses.size > 0
	delete_addresses.each do |address|
		person_to_keep.addresses.push(address)
		address.save
		person_to_keep.save
	end
elsif keep_addresses.size == 0 && delete_addresses.size == 0
	puts "Person has no addresses - may want to look into that."
	puts "#{person_to_keep.full_name} - #{hbx_id_keep}"
	puts "-"*30
elsif keep_addresses.size > 0 && delete_addresses.size > 0
	delete_addresses.each do |d_address|
		matches = []
		keep_addresses.each do |k_address|
			response = d_address.match(k_address)
			matches.push(response)
		end
		if matches.all? {|match| match == false}
			person_to_keep.addresses.push(d_address)
		end
	end
end


### phones
keep_phones = person_to_keep.phones
delete_phones = person_to_delete.phones

if keep_addresses.size == 0 && delete_phones.size > 0
	delete_phones.each do |phone|
		person_to_keep.phones.push(phone)
		phone.save
		person_to_keep.save
	end
elsif keep_phones.size > 0 && delete_phones.size > 0
	delete_phones.each do |d_phone|
		matches = []
		keep_phones.each do |k_phone|
			response = d_phone.match(k_phone)
			matches.push(response)
		end
		if matches.all? {|match| match == false}
			person_to_keep.phones.push(d_phone)
		end
	end
end

### emails
keep_emails = person_to_keep.emails
delete_emails = person_to_delete.emails

if keep_emails.size == 0 && delete_emails.size > 0
	delete_emails.each do |email|
		person_to_keep.emails.push(email)
		email.save
		person_to_keep.save
	end
elsif keep_emails.size > 0 && delete_emails.size > 0
	delete_emails.each do |d_email|
		matches = []
		keep_emails.each do |k_email|
			response = d_email.match(k_email)
			matches.push(response)
		end
		if matches.all? {|match| match == false}
			person_to_keep.emails.push(d_email)
		end
	end
end

person_to_keep.save

person_to_delete.destroy