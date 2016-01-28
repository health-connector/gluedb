$logger = Logger.new("#{Rails.root}/log/update_carefirst_termination_dates#{Time.now.to_s.gsub(' ', '')}.log")

file_path = "/Users/CitadelFirm/Downloads/Recon set (1-14) CF MidMonthTerm-31 copy.csv"
$logger.info "policy.id,policy.aasm_state,expected_termination_date,enrollees_data"

CSV.foreach(file_path, :headers=>true) do |row|
  policy = Policy.find(row[0])

  # Ensure that all covered individuals on the policy have their coverage end dates updated.
  enrollees_data = ""
  policy.enrollees.each do |enrollee|

    # Do not update a covered individual's existing coverage end date if the existing end date
    # is earlier than the new coverage end date adjustment.
    if enrollee.coverage_end.present?
      if enrollee.coverage_end >  Date.strptime(row[7], "%m/%d/%Y")
        enrollee.coverage_end = Date.strptime(row[7], "%m/%d/%Y")
      else
        puts "coverage_end before calculated date"
      end
    else
      enrollee.coverage_end = Date.strptime(row[7], "%m/%d/%Y")
    end

    enrollees_data += ",#{enrollee.m_id},#{enrollee.coverage_end}"
  end

  # Ensure the policy status is Terminated, update if not.
  policy.aasm_state = "terminated" unless policy.terminated?
  policy.save!
  policy.reload
  $logger.info "#{policy.id},#{policy.aasm_state},#{row[7]}#{enrollees_data}"
end
