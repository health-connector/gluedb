graylog_file = "DOB_Change_Output_9_23-10_27.csv"

csv_rows = []

CSV.foreach(graylog_file, headers: true) do |row|
  hbx_id = row["individual_id"]
  person = Person.where("members.hbx_member_id" => hbx_id).first
  dob = person.members.map(&:dob).join(";")
  row["glue_dob"] = dob
  csv_rows << row
end

CSV.open("#{graylog_file.gsub("*.csv","")}_with_glue_data.csv","w") do |csv|
  csv << %w(timestamp source full_message individual_id message return_status submitted_timestamp glue_dob)
  csv_rows.each do |row|
    csv << row
  end
end