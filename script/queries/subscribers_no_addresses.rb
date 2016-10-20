# Finds all subscribers with no home address.
puts "Started at #{Time.now}"

subscriber_ids = []

Policy.all.each do |policy|
	next if policy.subscriber.blank?
	subscriber_ids.push(policy.subscriber.m_id)
end

subscriber_ids.uniq!

subscribers = Person.where("members.hbx_member_id" => {"$in" => subscriber_ids})

puts "Subscribers collected at #{Time.now}"

def find_previous_home_addresses(person)
	return [] if person.versions.blank?
	addresses = person.versions.map(&:home_address).compact.uniq.map(&:full_address).uniq
	return addresses
end

CSV.open("people_missing_addresses_#{Time.now.strftime('%Y%m%d%H%M')}.csv", "w") do |csv|
	csv << ["HBX ID", "First Name", "Middle Name", "Last Name", "Previous Home Addresses"]
	subscribers.each do |subscriber|
		if subscriber.home_address.blank?
			hbx_id = subscriber.authority_member_id
			first_name = subscriber.name_first
			middle_name = subscriber.name_middle
			last_name = subscriber.name_last
			previous_addresses = find_previous_home_addresses(subscriber).join('; ')
			csv << [hbx_id,first_name,middle_name,last_name,previous_addresses]
		else
			next
		end
	end
end

puts "Finished at #{Time.now}"