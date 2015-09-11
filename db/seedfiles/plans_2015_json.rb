puts "Importing 2015 plans"
plan_file = File.open("db/seedfiles/2015_plans.json", "r")
data = plan_file.read
plan_file.close
plan_data = JSON.load(data)
plan_data.each do |pd|
  plan = Plan.new(pd)
  plan.id = pd["id"]
  plan.save
end
puts "Finished importing 2015 plans"