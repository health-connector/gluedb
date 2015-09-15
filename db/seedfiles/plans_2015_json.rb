puts "Importing 2015 plans"
plan_file = File.open("db/seedfiles/2015_plans.json", "r")
data = plan_file.read
plan_file.close
plan_data = JSON.load(data)
counter = 0
plan_data.each do |pd|
  next if pd["renewal_plan_id"].blank?
  plan = Plan.find(pd["id"])
  plan.renewal_plan_id = pd["renewal_plan_id"]
  plan.save!
  counter += 1
end
puts "#{counter} 2015 plans updated with renewal_plan_id"
puts "Finished importing 2015 plans"