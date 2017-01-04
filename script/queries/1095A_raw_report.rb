require 'csv'

policies_2016 = Policy.where(:employer_id => nil,
                             :enrollees => {"$elemMatch" => {
                                :rel_code => "self",
                                :coverage_start => {"$gt" => Date.new(2015,12,31), "$lt" => Date.new(2017,1,1)}}})

policies_2016_filtered = policies_2016.reject{|pol| pol.canceled?}

def authority_member_policy(subscriber_hbx_id,subscriber_person)
  if subscriber_hbx_id == subscriber_person.authority_member_id
    return true
  else
    return false
  end
end

total_count = policies_2016_filtered.size

puts "#{Time.now} - 0/#{total_count}"

count = 0

Caches::MongoidCache.with_cache_for(Carrier, Plan) do
  CSV.open("all_2016_policies_for_reporting.csv","w") do |csv|
    csv << ["Glue Policy ID", "Enrollment Group ID", 
            "Subscriber First Name", "Subscriber Last Name", "Subscriber HBX ID", "Authority Member Policy?",
            "Metal Level","Carrier", "HIOS ID",
            "State","Coverage Start","Coverage End","Premium Amount Total","APTC"]
    policies_2016_filtered.each do |policy|
      count += 1
      puts "#{Time.now} - #{count}/#{total_count}" if (count % 100 == 0 || count == total_count)
      policy_id = policy._id
      eg_id = policy.eg_id
      subscriber_person = policy.subscriber.person
      first_name = subscriber_person.name_first
      last_name = subscriber_person.name_last
      hbx_id = policy.subscriber.m_id
      authority = authority_member_policy(hbx_id,subscriber_person)
      plan = Caches::MongoidCache.lookup(Plan, policy.plan_id) {policy.plan}
      metal_level = plan.metal_level
      carrier = Caches::MongoidCache.lookup(Carrier, policy.carrier_id) {policy.carrier}
      carrier_name = carrier.name
      hios_id = plan.hios_plan_id
      state = policy.aasm_state
      coverage_start = policy.policy_start
      coverage_end = policy.policy_end
      premium_amount_total = policy.pre_amt_tot
      aptc = policy.applied_aptc
      csv << [policy_id,eg_id,first_name,last_name,hbx_id,authority,metal_level,carrier_name,hios_id,state,coverage_start,coverage_end,premium_amount_total,aptc]
    end
  end
end