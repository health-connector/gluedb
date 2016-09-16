# Finds all the people in Glue who appear multiple times, based on DOB and SSN

no_members = []

def find_matches(dob,ssn,first_name,last_name)
	dob_ssn_matches = Person.where("members.dob" => dob, "members.ssn" => ssn)
	unless ssn.blank?
		ssn_matches = Person.where("members.ssn" => ssn)
		matches = (dob_ssn_matches+ssn_matches).uniq!
	else
		matches = dob_ssn_matches
	end
	return matches
end

def find_employers(person)
    if person.policies.blank?
            return "No Policies Found"
    elsif person.policies.any?{|policy| policy.is_shop?}
            employers = person.policies.map(&:employer).compact.uniq
            return employers
    elsif person.policies.all?{|policy| policy.market == "individual"}
            return "IVL"
    end
end

shop_rows = []

ivl_rows = []

puts "Started at #{Time.now}"

CSV.open("multiple_instances_in_glue_by_dob_and_ssn.csv","w") do |csv|
	csv << ["Person 1 HBX ID", "Person 1 First Name", "Person 1 Middle Name", "Person 1 Last Name","Person 1 SSN", "Person 1 DOB","Person 1 Employer Fein(s)","Person 1 Employer Name(s)",
			"Person 2 HBX ID", "Person 2 First Name", "Person 2 Middle Name", "Person 2 Last Name","Person 2 SSN", "Person 2 DOB","Person 2 Employer Fein(s)","Person 2 Employer Name(s)",
			"Person 3 HBX ID", "Person 3 First Name", "Person 3 Middle Name", "Person 3 Last Name","Person 3 SSN", "Person 3 DOB","Person 3 Employer Fein(s)","Person 3 Employer Name(s)",
			"Person 4 HBX ID", "Person 4 First Name", "Person 4 Middle Name", "Person 4 Last Name","Person 4 SSN", "Person 4 DOB","Person 4 Employer Fein(s)","Person 4 Employer Name(s)",
			"Person 5 HBX ID", "Person 5 First Name", "Person 5 Middle Name", "Person 5 Last Name","Person 5 SSN", "Person 5 DOB","Person 5 Employer Fein(s)","Person 5 Employer Name(s)",
			"Person 6 HBX ID", "Person 6 First Name", "Person 6 Middle Name", "Person 6 Last Name","Person 6 SSN", "Person 6 DOB","Person 6 Employer Fein(s)","Person 6 Employer Name(s)",
			"Person 7 HBX ID", "Person 7 First Name", "Person 7 Middle Name", "Person 7 Last Name","Person 7 SSN", "Person 7 DOB","Person 7 Employer Fein(s)","Person 7 Employer Name(s)",
			"Person 8 HBX ID", "Person 8 First Name", "Person 8 Middle Name", "Person 8 Last Name","Person 8 SSN", "Person 8 DOB","Person 8 Employer Fein(s)","Person 8 Employer Name(s)",
			"Person 9 HBX ID", "Person 9 First Name", "Person 9 Middle Name", "Person 9 Last Name","Person 9 SSN", "Person 9 DOB","Person 9 Employer Fein(s)","Person 9 Employer Name(s)",
			"Person 10 HBX ID", "Person 10 First Name", "Person 10 Middle Name", "Person 10 Last Name","Person 10 SSN", "Person 10 DOB","Person 10 Employer Fein(s)","Person 10 Employer Name(s)",
			"Person 11 HBX ID", "Person 11 First Name", "Person 11 Middle Name", "Person 11 Last Name","Person 11 SSN", "Person 11 DOB","Person 11 Employer Fein(s)","Person 11 Employer Name(s)",
			"Person 12 HBX ID", "Person 12 First Name", "Person 12 Middle Name", "Person 12 Last Name","Person 12 SSN", "Person 12 DOB","Person 12 Employer Fein(s)","Person 12 Employer Name(s)",
			"Person 13 HBX ID", "Person 13 First Name", "Person 13 Middle Name", "Person 13 Last Name","Person 13 SSN", "Person 13 DOB","Person 13 Employer Fein(s)","Person 13 Employer Name(s)",
			"Person 14 HBX ID", "Person 14 First Name", "Person 14 Middle Name", "Person 14 Last Name","Person 14 SSN", "Person 14 DOB","Person 14 Employer Fein(s)","Person 14 Employer Name(s)",
			"Person 15 HBX ID", "Person 15 First Name", "Person 15 Middle Name", "Person 15 Last Name","Person 15 SSN", "Person 15 DOB","Person 15 Employer Fein(s)","Person 15 Employer Name(s)",
			"Person 16 HBX ID", "Person 16 First Name", "Person 16 Middle Name", "Person 16 Last Name","Person 16 SSN", "Person 16 DOB","Person 16 Employer Fein(s)","Person 16 Employer Name(s)",
			"Person 17 HBX ID", "Person 17 First Name", "Person 17 Middle Name", "Person 17 Last Name","Person 17 SSN", "Person 17 DOB","Person 17 Employer Fein(s)","Person 17 Employer Name(s)",
			"Person 18 HBX ID", "Person 18 First Name", "Person 18 Middle Name", "Person 18 Last Name","Person 18 SSN", "Person 18 DOB","Person 18 Employer Fein(s)","Person 18 Employer Name(s)",
			"Person 19 HBX ID", "Person 19 First Name", "Person 19 Middle Name", "Person 19 Last Name","Person 19 SSN", "Person 19 DOB","Person 19 Employer Fein(s)","Person 19 Employer Name(s)",
			"Person 20 HBX ID", "Person 20 First Name", "Person 20 Middle Name", "Person 20 Last Name","Person 20 SSN", "Person 20 DOB","Person 20 Employer Fein(s)","Person 20 Employer Name(s)",
			"Person 21 HBX ID", "Person 21 First Name", "Person 21 Middle Name", "Person 21 Last Name","Person 21 SSN", "Person 21 DOB","Person 21 Employer Fein(s)","Person 21 Employer Name(s)"]
	skips = []
	count = 0
	total_count = Person.all.size
	Person.all.each do |person|
		count += 1
		puts "#{Time.now} - #{count}/#{total_count}" if count % 10000 == 0
		begin
		if skips.include?(person)
			next
		end
		unless person.members.blank?
			dob = person.authority_member.dob
			ssn = person.authority_member.ssn
		else
			no_members.push("#{person.full_name}")
			next
		end
		unless dob.blank? && ssn.blank?
			matches = find_matches(dob,ssn,person.name_first,person.name_last)
		else
			next
		end
		if matches.size > 1
			row = []
			shop_boolean = []
			matches.each do |match|
				skips.push(match)
				unless match.members.blank?
					hbx_id = match.members.map(&:hbx_member_id).join(";")
					first_name = match.name_first
					middle_name = match.name_middle
					last_name = match.name_last
					ssn = match.members.map(&:ssn).uniq.join(";")
					dob = match.members.map(&:dob).uniq.join(";")
					employers = find_employers(match)
					if employers.class.to_s.downcase == "array"
						feins = employers.map(&:fein).uniq.join(";")
						names = employers.map(&:name).uniq.join(";")
						shop_boolean.push(true)
					else
						feins = "N/A"
						names = employers
						shop_boolean.push(false)
					end
					row.push(hbx_id,first_name,middle_name,last_name,ssn,dob,feins,names)
				else
					hbx_id = nil
					first_name = match.name_first
					middle_name = match.name_middle
					last_name = match.name_last
					ssn = nil
					dob = nil
					row.push(hbx_id,first_name,middle_name,last_name,ssn,dob,feins,name)
					no_members.push("#{person.full_name}")
				end
			end
			if shop_boolean.any?{|tf| tf == true}
				shop_rows.push(row)
			else
				ivl_rows.push(row)
			end
			csv << row
		else
		end
		rescue Exception=>e
			puts "#{person.full_name} - #{e.inspect}"
		end
	end
end

shop_file = File.new("multiple_instances_in_glue_by_dob_and_ssn_shop.csv","w")
shop_file << ["Person 1 HBX ID", "Person 1 First Name", "Person 1 Middle Name", "Person 1 Last Name","Person 1 SSN", "Person 1 DOB","Person 1 Employer Fein(s)","Person 1 Employer Name(s)",
			"Person 2 HBX ID", "Person 2 First Name", "Person 2 Middle Name", "Person 2 Last Name","Person 2 SSN", "Person 2 DOB","Person 2 Employer Fein(s)","Person 2 Employer Name(s)",
			"Person 3 HBX ID", "Person 3 First Name", "Person 3 Middle Name", "Person 3 Last Name","Person 3 SSN", "Person 3 DOB","Person 3 Employer Fein(s)","Person 3 Employer Name(s)",
			"Person 4 HBX ID", "Person 4 First Name", "Person 4 Middle Name", "Person 4 Last Name","Person 4 SSN", "Person 4 DOB","Person 4 Employer Fein(s)","Person 4 Employer Name(s)",
			"Person 5 HBX ID", "Person 5 First Name", "Person 5 Middle Name", "Person 5 Last Name","Person 5 SSN", "Person 5 DOB","Person 5 Employer Fein(s)","Person 5 Employer Name(s)",
			"Person 6 HBX ID", "Person 6 First Name", "Person 6 Middle Name", "Person 6 Last Name","Person 6 SSN", "Person 6 DOB","Person 6 Employer Fein(s)","Person 6 Employer Name(s)",
			"Person 7 HBX ID", "Person 7 First Name", "Person 7 Middle Name", "Person 7 Last Name","Person 7 SSN", "Person 7 DOB","Person 7 Employer Fein(s)","Person 7 Employer Name(s)",
			"Person 8 HBX ID", "Person 8 First Name", "Person 8 Middle Name", "Person 8 Last Name","Person 8 SSN", "Person 8 DOB","Person 8 Employer Fein(s)","Person 8 Employer Name(s)",
			"Person 9 HBX ID", "Person 9 First Name", "Person 9 Middle Name", "Person 9 Last Name","Person 9 SSN", "Person 9 DOB","Person 9 Employer Fein(s)","Person 9 Employer Name(s)",
			"Person 10 HBX ID", "Person 10 First Name", "Person 10 Middle Name", "Person 10 Last Name","Person 10 SSN", "Person 10 DOB","Person 10 Employer Fein(s)","Person 10 Employer Name(s)",
			"Person 11 HBX ID", "Person 11 First Name", "Person 11 Middle Name", "Person 11 Last Name","Person 11 SSN", "Person 11 DOB","Person 11 Employer Fein(s)","Person 11 Employer Name(s)",
			"Person 12 HBX ID", "Person 12 First Name", "Person 12 Middle Name", "Person 12 Last Name","Person 12 SSN", "Person 12 DOB","Person 12 Employer Fein(s)","Person 12 Employer Name(s)",
			"Person 13 HBX ID", "Person 13 First Name", "Person 13 Middle Name", "Person 13 Last Name","Person 13 SSN", "Person 13 DOB","Person 13 Employer Fein(s)","Person 13 Employer Name(s)",
			"Person 14 HBX ID", "Person 14 First Name", "Person 14 Middle Name", "Person 14 Last Name","Person 14 SSN", "Person 14 DOB","Person 14 Employer Fein(s)","Person 14 Employer Name(s)",
			"Person 15 HBX ID", "Person 15 First Name", "Person 15 Middle Name", "Person 15 Last Name","Person 15 SSN", "Person 15 DOB","Person 15 Employer Fein(s)","Person 15 Employer Name(s)",
			"Person 16 HBX ID", "Person 16 First Name", "Person 16 Middle Name", "Person 16 Last Name","Person 16 SSN", "Person 16 DOB","Person 16 Employer Fein(s)","Person 16 Employer Name(s)",
			"Person 17 HBX ID", "Person 17 First Name", "Person 17 Middle Name", "Person 17 Last Name","Person 17 SSN", "Person 17 DOB","Person 17 Employer Fein(s)","Person 17 Employer Name(s)",
			"Person 18 HBX ID", "Person 18 First Name", "Person 18 Middle Name", "Person 18 Last Name","Person 18 SSN", "Person 18 DOB","Person 18 Employer Fein(s)","Person 18 Employer Name(s)",
			"Person 19 HBX ID", "Person 19 First Name", "Person 19 Middle Name", "Person 19 Last Name","Person 19 SSN", "Person 19 DOB","Person 19 Employer Fein(s)","Person 19 Employer Name(s)",
			"Person 20 HBX ID", "Person 20 First Name", "Person 20 Middle Name", "Person 20 Last Name","Person 20 SSN", "Person 20 DOB","Person 20 Employer Fein(s)","Person 20 Employer Name(s)",
			"Person 21 HBX ID", "Person 21 First Name", "Person 21 Middle Name", "Person 21 Last Name","Person 21 SSN", "Person 21 DOB","Person 21 Employer Fein(s)","Person 21 Employer Name(s)"].to_csv
shop_rows.each do |shop_row|
	shop_file.puts(shop_row.to_csv)
end

ivl_file = File.new("multiple_instances_in_glue_by_dob_and_ssn_ivl.csv","w")
ivl_file << ["Person 1 HBX ID", "Person 1 First Name", "Person 1 Middle Name", "Person 1 Last Name","Person 1 SSN", "Person 1 DOB","Person 1 Employer Fein(s)","Person 1 Employer Name(s)",
			"Person 2 HBX ID", "Person 2 First Name", "Person 2 Middle Name", "Person 2 Last Name","Person 2 SSN", "Person 2 DOB","Person 2 Employer Fein(s)","Person 2 Employer Name(s)",
			"Person 3 HBX ID", "Person 3 First Name", "Person 3 Middle Name", "Person 3 Last Name","Person 3 SSN", "Person 3 DOB","Person 3 Employer Fein(s)","Person 3 Employer Name(s)",
			"Person 4 HBX ID", "Person 4 First Name", "Person 4 Middle Name", "Person 4 Last Name","Person 4 SSN", "Person 4 DOB","Person 4 Employer Fein(s)","Person 4 Employer Name(s)",
			"Person 5 HBX ID", "Person 5 First Name", "Person 5 Middle Name", "Person 5 Last Name","Person 5 SSN", "Person 5 DOB","Person 5 Employer Fein(s)","Person 5 Employer Name(s)",
			"Person 6 HBX ID", "Person 6 First Name", "Person 6 Middle Name", "Person 6 Last Name","Person 6 SSN", "Person 6 DOB","Person 6 Employer Fein(s)","Person 6 Employer Name(s)",
			"Person 7 HBX ID", "Person 7 First Name", "Person 7 Middle Name", "Person 7 Last Name","Person 7 SSN", "Person 7 DOB","Person 7 Employer Fein(s)","Person 7 Employer Name(s)",
			"Person 8 HBX ID", "Person 8 First Name", "Person 8 Middle Name", "Person 8 Last Name","Person 8 SSN", "Person 8 DOB","Person 8 Employer Fein(s)","Person 8 Employer Name(s)",
			"Person 9 HBX ID", "Person 9 First Name", "Person 9 Middle Name", "Person 9 Last Name","Person 9 SSN", "Person 9 DOB","Person 9 Employer Fein(s)","Person 9 Employer Name(s)",
			"Person 10 HBX ID", "Person 10 First Name", "Person 10 Middle Name", "Person 10 Last Name","Person 10 SSN", "Person 10 DOB","Person 10 Employer Fein(s)","Person 10 Employer Name(s)",
			"Person 11 HBX ID", "Person 11 First Name", "Person 11 Middle Name", "Person 11 Last Name","Person 11 SSN", "Person 11 DOB","Person 11 Employer Fein(s)","Person 11 Employer Name(s)",
			"Person 12 HBX ID", "Person 12 First Name", "Person 12 Middle Name", "Person 12 Last Name","Person 12 SSN", "Person 12 DOB","Person 12 Employer Fein(s)","Person 12 Employer Name(s)",
			"Person 13 HBX ID", "Person 13 First Name", "Person 13 Middle Name", "Person 13 Last Name","Person 13 SSN", "Person 13 DOB","Person 13 Employer Fein(s)","Person 13 Employer Name(s)",
			"Person 14 HBX ID", "Person 14 First Name", "Person 14 Middle Name", "Person 14 Last Name","Person 14 SSN", "Person 14 DOB","Person 14 Employer Fein(s)","Person 14 Employer Name(s)",
			"Person 15 HBX ID", "Person 15 First Name", "Person 15 Middle Name", "Person 15 Last Name","Person 15 SSN", "Person 15 DOB","Person 15 Employer Fein(s)","Person 15 Employer Name(s)",
			"Person 16 HBX ID", "Person 16 First Name", "Person 16 Middle Name", "Person 16 Last Name","Person 16 SSN", "Person 16 DOB","Person 16 Employer Fein(s)","Person 16 Employer Name(s)",
			"Person 17 HBX ID", "Person 17 First Name", "Person 17 Middle Name", "Person 17 Last Name","Person 17 SSN", "Person 17 DOB","Person 17 Employer Fein(s)","Person 17 Employer Name(s)",
			"Person 18 HBX ID", "Person 18 First Name", "Person 18 Middle Name", "Person 18 Last Name","Person 18 SSN", "Person 18 DOB","Person 18 Employer Fein(s)","Person 18 Employer Name(s)",
			"Person 19 HBX ID", "Person 19 First Name", "Person 19 Middle Name", "Person 19 Last Name","Person 19 SSN", "Person 19 DOB","Person 19 Employer Fein(s)","Person 19 Employer Name(s)",
			"Person 20 HBX ID", "Person 20 First Name", "Person 20 Middle Name", "Person 20 Last Name","Person 20 SSN", "Person 20 DOB","Person 20 Employer Fein(s)","Person 20 Employer Name(s)",
			"Person 21 HBX ID", "Person 21 First Name", "Person 21 Middle Name", "Person 21 Last Name","Person 21 SSN", "Person 21 DOB","Person 21 Employer Fein(s)","Person 21 Employer Name(s)"].to_csv
ivl_rows.each do |ivl_row|
	ivl_file.puts(ivl_row.to_csv)
end

no_members_file = File.new("people_with_no_members.txt","w")
no_members.each do |nm|
	no_members_file.puts(nm)
end

puts "Ended at #{Time.now}"
