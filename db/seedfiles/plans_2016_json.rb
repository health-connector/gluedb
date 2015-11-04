puts "Importing 2016 plans"
plan_file = File.open("db/seedfiles/2016_plans.json", "r")
data = plan_file.read
plan_file.close
plan_data = JSON.load(data)
puts "Before total #{Plan.count} plans"
puts "#{plan_data.size} plans in json file"
plan_data.each do |pd|
  plan = Plan.where(hios_plan_id:pd["hios_plan_id"]).first
  plan.update_attributes(pd)
  plan.id = pd['id'] #use the id from json
  plan.save
end
puts "After total #{Plan.count} plans"
puts "Finished importing 2016 plans"