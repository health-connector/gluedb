puts "Importing 2016 plans"
plan_file = File.open("db/seedfiles/2016_plans.json", "r")
data = plan_file.read
plan_file.close
plan_data = JSON.load(data)
plan_data.each do |pd|
  Plan.create!(pd)
end
puts "Finished importing 2016 plans"