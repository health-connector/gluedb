require 'csv'

header_row = ["Glue_Policy_ID", "Enrollment_Group_ID", "Subscriber_First_Name", "Subscriber_Last_Name", "Subscriber_HBX_ID", "Authority_Member_Policy?", "Metal_Level", "Carrier", "HIOS_ID", "State", "Coverage_Start", "Coverage_End", "Premium_Amount_Total", "APTC"]

CSV.open("catastrophic_plans_report_for_2017.csv","w") do |csv|
  csv << header_row
  catastrophic_plan_ids = Plan.where(metal_level: "catastrophic").map(&:id)
  policies = Policy.where(:"plan_id".in => catastrophic_plan_ids )
  policies.each do |policy|
    next if !(policy.subscriber.coverage_start.year == 2017)
    begin
      csv << [
        policy.id,
        policy.eg_id,
        policy.subscriber.person.name_first,
        policy.subscriber.person.name_last,
        policy.subscriber.m_id,
        policy.belong_to_authority_member?,
        policy.plan.metal_level,
        policy.carrier,
        policy.plan.hios_plan_id,
        policy.aasm_state,
        policy.subscriber.coverage_start,
        policy.subscriber.coverage_end,
        policy.pre_amt_tot,
        policy.applied_aptc
      ]
    rescue => e
      puts e.backtrace unless Rails.env.test?
    end
  end
end
