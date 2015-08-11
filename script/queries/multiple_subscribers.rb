require 'pry'
require 'csv'

puts Time.now
puts "Pulling in policies with multiple subscribers."
multiple_enrollees = Policy.collection.find({"enrollees.1" => {"$exists" => true}})
puts Time.now
puts "Done pulling in."

total_count = multiple_enrollees.count

mult_subs = []

puts "#{total_count} to go, here we go!"

multiple_enrollees.each do |pol|
	count = 0
	subcount = 0
	pol["enrollees"].each do |enr|
		if enr["rel_code"] == "self"
			subcount +=1
		end
	end
	if subcount > 1
		mult_subs.push(pol)
	end
	count += 1
	if count % 100 == 0
		puts "#{count} done so far!"
	end
end

CSV.open("multiple_subscribers.csv","w") do |csv|
	csv << ["Policy ID", "Enrollment Group ID", "AASM State", "HBX ID", "Name"]
	mult_subs.each do |pol|
		policy_id = pol["_id"]
		eg_id = pol["eg_id"]
		aasm = pol["aasm_state"]
		firstsub = pol["enrollees"].first
		hbx_id = firstsub["m_id"]
		name = Policy.find_by(_id: policy_id).enrollees.first.person.full_name
		csv << [policy_id, eg_id, aasm, hbx_id, name]
	end
end