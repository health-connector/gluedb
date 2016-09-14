# Finds all the people in Glue who appear multiple times, based on DOB and SSN

pb = ProgressBar.create(
      :title => "Checking People",
      :total => Person.all.size,
      :format => "%t %a %e |%B| %P%%"
   )

no_members = []

skips = []

def find_matches(dob,ssn,first_name,last_name)
	dob_ssn_matches = Person.where("members.dob" => dob, "members.ssn" => ssn)
	ssn_matches = Person.where("members.ssn" => ssn)
	name_matches = Person.where(name_first: /#{first_name}/i, name_last: /#{last_name}/i)
	matches = (dob_ssn_matches+ssn_matches+name_matches).uniq
	return matches
end

CSV.open("multiple_instances_in_glue.csv","w") do |csv|
	csv << ["Person 1 HBX ID", "Person 1 First Name", "Person 1 Middle Name", "Person 1 Last Name","Person 1 SSN", "Person 1 DOB",
			"Person 2 HBX ID", "Person 2 First Name", "Person 2 Middle Name", "Person 2 Last Name","Person 2 SSN", "Person 2 DOB",
			"Person 3 HBX ID", "Person 3 First Name", "Person 3 Middle Name", "Person 3 Last Name","Person 3 SSN", "Person 3 DOB"]
	Person.all.each do |person|
		begin
		if skips.include?(person)
			pb.increment
			next
		end
		unless person.members.blank?
			dob = person.authority_member.dob
			ssn = person.authority_member.ssn
		else
			no_members.push("#{person.full_name}")
			pb.increment
			next
		end
		matches = find_matches(dob,ssn,person.name_first,person.name_last)
		if matches.size > 1
			row = []
			matches.each do |match|
				skips.push(match)
				unless match.members.blank?
					hbx_id = match.members.map(&:hbx_member_id).join(",")
					first_name = match.name_first
					middle_name = match.name_middle
					last_name = match.name_last
					ssn = match.members.map(&:ssn).uniq.join(",")
					dob = match.members.map(&:dob).uniq.join(",")
					row.push(hbx_id,first_name,middle_name,last_name,ssn,dob)
				else
					hbx_id = nil
					first_name = match.name_first
					middle_name = match.name_middle
					last_name = match.name_last
					ssn = nil
					dob = nil
					row.push(hbx_id,first_name,middle_name,last_name,ssn,dob)
					no_members.push("#{person.full_name}")
				end
			end
			pb.increment
			csv << row
		else
			pb.increment
		end
		rescue Exception=>e
			puts "#{person.full_name} - #{e.inspect}"
		end
	end
end

no_members_file = File.new("people_with_no_members.txt","w")
no_members.each do |nm|
	no_members_file.puts(nm)
end
