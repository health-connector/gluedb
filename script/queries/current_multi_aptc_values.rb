filenames = []

filenames.each do |fn|
  policy_ids = []
  CSV.foreach(fn, headers: true) do |row|
    policy_ids << row["Policy ID"]
  end
  policy_ids.uniq!
  CSV.open("#{fn.gsub(".csv","")}_current_aptc_values_#{Time.now.strftime('%Y%m%d%H%M')}.csv","w") do |csv|
    csv << ["Policy ID", "EG ID", "Subscriber Name","Subscriber HBX ID", "Policy Premium Amount Total", "Policy APTC", "Policy Responsible Amount", 
          "APTC Credit Amount", "APTC Credit Start", "APTC Credit End"]
    policy_ids.each do |id|
      policy = Policy.find(id)
      next if policy.blank?
      policy_id = policy.id
      eg_id = policy.eg_id
      subscriber_name = policy.subscriber.person.full_name
      subscriber_hbx_id = policy.subscriber.m_id
      pre_amt_tot = policy.pre_amt_tot
      aptc = policy.applied_aptc
      responsible = policy.tot_res_amt
      policy.aptc_credits.each do |ac|
        csv << [policy_id,eg_id,subscriber_name,subscriber_hbx_id,pre_amt_tot,aptc,responsible,ac.aptc,ac.start_on,ac.end_on]
      end
    end
  end
end