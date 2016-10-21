#script to generate a report for Curam team-11093
def policy_calculator(policy)
  renewal_policy = policy.clone_for_renewal(Date.new(2017, 1, 1))
  return if renewal_policy.plan.nil?  
  pc = ::Premiums::PolicyCalculator.new
  pc.apply_calculations(renewal_policy)
  renewal_policy
end

report_csv =CSV.open("/Users/Varun/Desktop/reports/oct_18/report_for_curam_oct_19_6_uqhp.csv", "w")

report_csv << %w(applid ic_ref firstname lastname aptc csr hbxid coverage_type_1 policy.qhp.eg_id 2016qhp 2017crossover_renewal_qhp 2016_qhp_premium 2017_health_premium coverage_type_2 policy.dental.eg_id 2016_dental 2017crossover_renewal_dental 2016_dental_premium 2017_dental_premium)
begin
  csv = CSV.open('/Users/Varun/Downloads/new_rev101316/uqhp_101316.csv',"r",:headers =>true,:encoding => 'ISO-8859-1')
  @data= csv.to_a
  @data.each do |d|
    person = Person.where(:authority_member_id => d["hbxid"]).first
    begin
      if person.present? && d["subscriber"].downcase == "y"
        policies = person.policies.includes(:plan).where("enrollees.coverage_start" => {"$gt" => Date.new(2015,12,31)}).to_a
        active_health_policies = policies.select{|p| p.is_active? && p.plan.coverage_type == 'health'}
        active_health_policy = active_health_policies.sort{|x,y| y.enrollees.first.coverage_start <=> x.enrollees.first.coverage_start}.first
        active_dental_policies = policies.select{|p| p.is_active? && p.plan.coverage_type == 'dental'}
        active_dental_policy = active_dental_policies.sort{|x,y| y.enrollees.first.coverage_start <=> x.enrollees.first.coverage_start}.first
        row = [d["applid"],  d["ic_ref"], d["firstname"], d["lastname"], d["aptc"],  d["csr"], d["hbxid"]]
        if active_health_policy 
          row += [active_health_policy.coverage_type, active_health_policy.eg_id, active_health_policy.plan.name, active_health_policy.plan.try(:renewal_plan).try(:name), active_health_policy.pre_amt_tot.to_s]
          renewal_health = policy_calculator(active_health_policy)
          row += [renewal_health.try(:pre_amt_tot)]
        end
        if active_dental_policy
          row += [active_dental_policy.plan.coverage_type, active_dental_policy.eg_id, active_dental_policy.plan.name, active_dental_policy.plan.try(:renewal_plan).try(:name), active_dental_policy.pre_amt_tot.to_s]
          renewal_dental= policy_calculator(active_dental_policy)
          row += [renewal_dental.try(:pre_amt_tot)]
        end
        report_csv << row
      end
    rescue Exception => e
      puts "Error #{e} #{e.backtrace}"
    end
  end  
rescue Exception => e
  puts "Unable to open file #{e} #{e.backtrace}"
end
