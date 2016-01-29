$logger = Logger.new("#{Rails.root}/log/update_carefirst_termination_dates#{Time.now.to_s.gsub(' ', '')}.log")

file_path = "/Users/CitadelFirm/Downloads/Recon set (1-14) CF MidMonthTerm-31.csv"

$logger.info "policy.id,policy.aasm_state,expected_termination_date,all enrollees data (m_id,coverage_end date)"

CSV.foreach(file_path, :headers => true) do |row|

  begin
    policy = Policy.find(row[0])

    # Ensure that all covered individuals on the policy have their coverage end dates updated.
    enrollees_data = ""
    policy.enrollees.each do |enrollee|

      # Do not update a covered individual's existing coverage end date if the existing end date
      # is earlier than the new coverage end date adjustment.
      original_coverage_end = enrollee.coverage_end
      if enrollee.coverage_end.present?
        if enrollee.coverage_end > Date.strptime(row[7], "%m/%d/%Y")
          enrollee.coverage_end = Date.strptime(row[7], "%m/%d/%Y")
        else
          puts "coverage_end before calculated date"
        end
      else
        enrollee.coverage_end = Date.strptime(row[7], "%m/%d/%Y")
      end

      person = enrollee.person

      person.comments.build({content: "CF 1095-A Recon: Coverage end date changed from #{original_coverage_end}
                                        to #{enrollee.coverage_end} for policy #{policy.id}", user: 'script', created_at: Time.now, updated_at: Time.now})

      person.save
      enrollee.save
      enrollees_data += ",#{enrollee.m_id},#{enrollee.coverage_end}"
    end

    # Ensure the policy status is Terminated, update if not.
    policy.aasm_state = "terminated" unless policy.terminated?
    policy.save!
    policy.reload
    $logger.info "#{policy.id},#{policy.aasm_state},#{row[7]}#{enrollees_data}"

  rescue Exception => e
    puts e.message
  end

end
