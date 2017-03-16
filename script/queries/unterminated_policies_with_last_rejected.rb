# Checks all policies without an end date and finds which has a rejected transaction as the last rejection.

policies = Policy.where({:enrollees => {"$elemMatch" => {:rel_code => "self", :coverage_end => {"$eq" => nil}}}})

count = 0
total_count = policies.size

Caches::MongoidCache.with_cache_for(Plan, Employer) do
  CSV.open("policies_with_rejected_transaction.csv","w") do |csv|
    csv << ["Subsciber HBX ID", "Enrollment Group ID", "Start Date", "End Date","Market","Plan HIOS ID", "Plan Metal", "Employer Name","Employer FEIN"]
    policies.each do |policy|
      puts "#{count}/#{total_count} - #{Time.now}" if count % 10000 == 0 || count == 0
      count += 1
      next if policy.transaction_set_enrollments.size == 0
      next if policy.subscriber.blank?
      last_transaction = policy.transaction_set_enrollments.sort_by{|tse| tse.submitted_at}.last
      if last_transaction.aasm_state == "rejected"
        subscriber_hbx_id = policy.subscriber.m_id
        eg_id = policy.eg_id
        start_date = policy.policy_start
        end_date = policy.policy_end
        market = policy.market
        if policy.is_shop?
          employer = Caches::MongoidCache.lookup(Employer, policy.employer_id) {policy.employer}
          employer_name = employer.name
          employer_fein = employer.fein
        end
        plan = Caches::MongoidCache.lookup(Plan, policy.plan_id) {policy.plan}
        plan_hios = plan.hios_plan_id
        plan_metal = plan.metal_level
        csv << [subscriber_hbx_id,eg_id,start_date,end_date,market,plan_hios,plan_metal,employer_name,employer_fein]
      end
    end
  end
end