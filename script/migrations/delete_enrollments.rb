## ONLY USE THIS CODE IN THE MOST DIRE OF EMERGENCIES.

eg_ids = Array.new

File.readlines(policies_to_delete.txt).map do |line|
    eg_ids.push(line.to_s)
end

policies_to_delete = Policy.where(:eg_id => {"$in" => eg_ids})

policies_to_delete.each do |policy|
	policy.destroy
end