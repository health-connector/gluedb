# Identify and count bad records

all_2017_mpy_pys = PlanYear.where({plan_catalog_override: 2017})

should_start_2018_1_1 = all_2017_mpy_pys.where({start_date: Date.new(2018,4,1), end_date: Date.new(2018,12,31)})
should_start_2018_2_1 = all_2017_mpy_pys.where({start_date: Date.new(2018,4,1), end_date: Date.new(2019,1,31)})
should_start_2018_3_1 = all_2017_mpy_pys.where({start_date: Date.new(2018,4,1), end_date: Date.new(2019,2,28)})
should_start_2018_4_1 = all_2017_mpy_pys.where({start_date: Date.new(2018,4,1), end_date: Date.new(2019,3,31)})

puts "\n\nErroneous 2018 MPY Plan Years Marked as 2017:"
puts "01/01/2018: #{should_start_2018_1_1.count}"
puts "02/01/2018: #{should_start_2018_2_1.count}"
puts "03/01/2018: #{should_start_2018_3_1.count}"
puts "04/01/2018: #{should_start_2018_4_1.count}"
puts "     Total: #{should_start_2018_1_1.count + should_start_2018_2_1.count + should_start_2018_3_1.count + should_start_2018_4_1.count}"

employer_ids_1_1 = should_start_2018_1_1.map(&:employer_id).uniq
employer_ids_2_1 = should_start_2018_2_1.map(&:employer_id).uniq
employer_ids_3_1 = should_start_2018_3_1.map(&:employer_id).uniq
employer_ids_4_1 = should_start_2018_4_1.map(&:employer_id).uniq

plans_for_2017_ids = Plan.where(year: 2017).map(&:id)

employer_1_1_policies = Policy.where({"employer_id" => {"$in" => employer_ids_1_1}, "plan_id" => {"$in" => plans_for_2017_ids}}).select do |pol|
  pol.subscriber.coverage_start >= Date.new(2018,4,1)
end

employer_2_1_policies = Policy.where({"employer_id" => {"$in" => employer_ids_2_1}, "plan_id" => {"$in" => plans_for_2017_ids}}).select do |pol|
  pol.subscriber.coverage_start >= Date.new(2018,4,1)
end

employer_3_1_policies = Policy.where({"employer_id" => {"$in" => employer_ids_3_1}, "plan_id" => {"$in" => plans_for_2017_ids}}).select do |pol|
  pol.subscriber.coverage_start >= Date.new(2018,4,1)
end

employer_4_1_policies = Policy.where({"employer_id" => {"$in" => employer_ids_4_1}, "plan_id" => {"$in" => plans_for_2017_ids}}).select do |pol|
  pol.subscriber.coverage_start >= Date.new(2018,4,1)
end

puts "\n\nErroneous 2018 MPY Policies Marked as 2017:"
puts "01/01/2018: #{employer_1_1_policies.count}"
puts "02/01/2018: #{employer_2_1_policies.count}"
puts "03/01/2018: #{employer_3_1_policies.count}"
puts "04/01/2018: #{employer_4_1_policies.count}"
puts "     Total: #{employer_1_1_policies.count + employer_2_1_policies.count + employer_3_1_policies.count + employer_4_1_policies.count}"

# Correct bad records - start with policies first

puts "\n\nCorrecting Policies:"

plans_for_2017 = Plan.where(year: 2017)
plans_for_2018 = Plan.where(year: 2018)

plans_for_2017_id_map = {}
plans_for_2017.each do |plan|
  plans_for_2017_id_map[plan.id] = plan.hios_plan_id
end

plans_for_2018_hios_map = {}
plans_for_2018.each do |plan|
  plans_for_2018_hios_map[plan.hios_plan_id] = plan
end

puts "Correcting policies for 1/1s"
employer_1_1_policies.each do |pol|
  correct_2018_plan = plans_for_2018_hios_map[plans_for_2017_id_map[pol.plan_id]]
  if correct_2018_plan
    pol.update_attributes!({plan: correct_2018_plan})
  else
    puts "Could not find plan match for: #{pol.eg_id}, #{pol.plan_id}"
  end
end

puts "Correcting policies for 2/1s"
employer_2_1_policies.each do |pol|
  correct_2018_plan = plans_for_2018_hios_map[plans_for_2017_id_map[pol.plan_id]]
  if correct_2018_plan
    pol.update_attributes!({plan: correct_2018_plan})
  else
    puts "Could not find plan match for: #{pol.eg_id}, #{pol.plan_id}"
  end
end

puts "Correcting policies for 3/1s"
employer_3_1_policies.each do |pol|
  correct_2018_plan = plans_for_2018_hios_map[plans_for_2017_id_map[pol.plan_id]]
  if correct_2018_plan
    pol.update_attributes!({plan: correct_2018_plan})
  else
    puts "Could not find plan match for: #{pol.eg_id}, #{pol.plan_id}"
  end
end

puts "Correcting policies for 4/1s"
employer_4_1_policies.each do |pol|
  correct_2018_plan = plans_for_2018_hios_map[plans_for_2017_id_map[pol.plan_id]]
  if correct_2018_plan
    pol.update_attributes!({plan: correct_2018_plan})
  else
    puts "Could not find plan match for: #{pol.eg_id}, #{pol.plan_id}"
  end
end


# Clean up plan years

puts "\n\nCorrecting Plan Years:"
puts "Correcting Plan Years for 1/1s"
should_start_2018_1_1.update_all("$unset" => {"plan_catalog_override" => 1})
puts "Correcting Plan Years for 2/1s"
should_start_2018_2_1.update_all("$unset" => {"plan_catalog_override" => 1})
puts "Correcting Plan Years for 3/1s"
should_start_2018_3_1.update_all("$unset" => {"plan_catalog_override" => 1})
puts "Correcting Plan Years for 4/1s"
should_start_2018_4_1.update_all("$unset" => {"plan_catalog_override" => 1})