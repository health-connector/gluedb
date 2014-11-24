require 'csv'

file_location = File.join(File.dirname(__FILE__), "missing_plans_2015.csv")

plans = []
CSV.foreach(File.open(file_location), headers: true) do |row|
  record = row.to_hash.dup
  carrier_id = Carrier.where(:abbrev => record["carrier_abbreviation"]).first._id
  record.delete("carrier_abbreviation")
  record["carrier_id"] = carrier_id
  record["year"] = record["year"].to_i
  plans << record
end

plans.each { |p| Plan.create!(p) }
