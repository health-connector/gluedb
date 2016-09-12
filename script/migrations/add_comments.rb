file_path = "redmine-7965.csv"

CSV.foreach(file_path, headers: true) do |row|
	begin
		row_hash = row.to_hash
		person = Person.unscoped.where("members.hbx_member_id" => row_hash["HBX ID"]).first
		unless person.blank?
			policy = Policy.find(row_hash["Policy ID"])
			if policy.canceled?
				person.comments.build({content: "CF IVL Recon: #{row_hash["HBX Enrollment Group ID"]} silently canceled due to consumer plan change.", 
									   user: 'chris.wiseman@dc.gov', 
									   created_at: Time.now, 
									   updated_at: Time.now})
				person.save
			elsif policy.terminated?
				person.comments.build({content: "CF IVL Recon: #{row_hash["HBX Enrollment Group ID"]} silently terminated due to consumer plan change.", 
									   user: 'chris.wiseman@dc.gov', 
									   created_at: Time.now, 
									   updated_at: Time.now})
				person.save
			end
		else
			puts "Member #{row_hash["HBX ID"]} not found."
		end
	rescue
	end
end