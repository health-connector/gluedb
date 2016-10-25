enroll_input_file = 'employer_list.csv' # The filename of the file coming from enroll

csv_rows = []

CSV.foreach(enroll_input_file,headers: true) do |enroll_row|
	employer_fein = Employer.where(fein: enroll_row['fein']).to_a
	glue_hbx_id = employer_fein.map(&:hbx_id).uniq.join(";")
	if glue_hbx_id != enroll_row['hbx_id']
		enroll_row['glue_hbx_id'] = glue_hbx_id
	else
		enroll_row['glue_hbx_id'] = ""
	end
	employer_hbx_id = Employer.where(hbx_id: enroll_row['hbx_id']).to_a
	glue_fein = employer_hbx_id.map(&:fein).uniq.join(";")
	if glue_fein != enroll_row['fein']
		enroll_row['glue_fein'] = glue_fein
	else
		enroll_row['glue_fein'] = ""
	end
	csv_rows.push(enroll_row)
end

CSV.open("#{enroll_input_file.gsub(".csv","")}_with_glue_data.csv","w") do |csv|
	csv << ["employer_legal_name","fein","dba","hbx_id","glue_hbx_id (if different)","glue_fein (if different)"]
	csv_rows.each do |csv_row|
		csv << csv_row
	end
end